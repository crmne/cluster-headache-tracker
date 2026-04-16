require "csv"

class HeadacheLog < ApplicationRecord
  CSV_HEADERS = %w[ start_time end_time intensity medication triggers notes ].freeze

  belongs_to :user

  validates :start_time, :intensity, presence: true
  validates :intensity, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }

  after_create_commit -> { broadcast_create }
  after_update_commit -> { broadcast_update }
  after_destroy_commit -> { broadcast_destroy }

  scope :chronological, -> { order(:start_time) }
  scope :recent_first, -> { order(start_time: :desc) }
  scope :started_after, ->(start_time) { where("start_time >= ?", Date.parse(start_time).beginning_of_day) }
  scope :ended_before, ->(end_time) { where("end_time <= ? OR end_time IS NULL", Date.parse(end_time).end_of_day) }
  scope :with_triggers, ->(triggers) { where("triggers ILIKE ?", "%#{triggers}%") }
  scope :with_medication, ->(medication) { where("medication ILIKE ?", "%#{medication}%") }

  class << self
    def filtered_by(params)
      headache_logs = all

      if params[:start_time].present?
        headache_logs = headache_logs.started_after(params[:start_time])
      end

      if params[:end_time].present?
        headache_logs = headache_logs.ended_before(params[:end_time])
      end

      if params[:triggers].present?
        headache_logs = headache_logs.with_triggers(params[:triggers])
      end

      if params[:medication].present?
        headache_logs = headache_logs.with_medication(params[:medication])
      end

      headache_logs
    end

    def chart_data
      headache_logs = chronological

      {
        intensity_data: intensity_data_for(headache_logs),
        trigger_data: trigger_data_for(headache_logs),
        medication_data: medication_data_for(headache_logs),
        hourly_data: hourly_data_for(headache_logs),
        attacks_per_day_data: attacks_per_day_data_for(headache_logs),
        duration_data: duration_data_for(headache_logs)
      }
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << CSV_HEADERS

        recent_first.each do |log|
          csv << [
            log.start_time&.strftime("%Y-%m-%d %H:%M:%S"),
            log.end_time&.strftime("%Y-%m-%d %H:%M:%S"),
            log.intensity.to_s,
            log.medication.to_s,
            log.triggers.to_s,
            log.notes.to_s
          ]
        end
      end
    end

    def import_csv(file:, user:)
      imported_logs = 0

      CSV.foreach(file.path, headers: true, header_converters: :symbol) do |row|
        headache_log = user.headache_logs.create(import_attributes_from(row))

        if headache_log.persisted?
          imported_logs += 1
        end
      end

      imported_logs
    end

    private
      def attacks_per_day_data_for(logs)
        attacks_per_day = logs.group_by { |log| log.start_time.to_date }
                              .transform_values(&:count)

        attacks_per_day.map { |date, count| { x: date.iso8601, y: count } }
      end

      def duration_data_for(logs)
        complete_logs = logs.reject { |log| log.end_time.nil? }

        complete_logs.map do |log|
          duration_hours = ((log.end_time - log.start_time) / 1.hour).round(2)

          {
            x: log.start_time.iso8601,
            y: duration_hours,
            intensity: log.intensity
          }
        end
      end

      def hourly_data_for(logs)
        hourly_data = Array.new(12) { { count: 0, total_intensity: 0 } }

        logs.each do |log|
          interval = log.start_time.hour / 2
          hourly_data[interval][:count] += 1
          hourly_data[interval][:total_intensity] += log.intensity
        end

        hourly_data.map.with_index do |data, index|
          start_hour = index * 2

          {
            label: "#{start_hour}:00 - #{start_hour + 1}:59",
            frequency: data[:count],
            avg_intensity: data[:count].positive? ? (data[:total_intensity].to_f / data[:count]).round(2) : 0
          }
        end
      end

      def import_attributes_from(row)
        {
          start_time: parse_time(row[:start_time]),
          end_time: parse_time(row[:end_time]),
          intensity: row[:intensity],
          medication: row[:medication],
          triggers: row[:triggers],
          notes: row[:notes]
        }
      end

      def intensity_data_for(logs)
        logs.map { |log| { x: log.start_time.iso8601, y: log.intensity } }
      end

      def medication_data_for(logs)
        medication_counts = Hash.new(0)

        logs.each do |log|
          medications = log.medication.to_s.split(",").map(&:strip).map(&:downcase)

          medications.each do |medication|
            medication_counts[medication] += 1 unless medication.blank?
          end
        end

        medication_counts.sort_by { |_, count| -count }.first(5).to_h
      end

      def parse_time(time_string)
        if time_string.present?
          Time.zone.parse(time_string)
        end
      end

      def trigger_data_for(logs)
        trigger_counts = Hash.new(0)

        logs.each do |log|
          triggers = log.triggers.to_s.split(",").map(&:strip)

          triggers.each do |trigger|
            trigger_counts[trigger] += 1 unless trigger.blank?
          end
        end

        trigger_counts.sort_by { |_, count| -count }.first(5).to_h
      end
  end

  def intensity_badge_class
    case intensity
    when 1..3
      "badge-success"
    when 4..6
      "badge-warning"
    when 7..10
      "badge-error"
    else
      "badge-ghost"
    end
  end

  private
    def broadcast_create
      if user.headache_logs.count == 1
        broadcast_replace_to [ user, "headache_logs" ], target: "headache_logs",
                                                       partial: "headache_logs/logs_grid",
                                                       locals: { headache_logs: user.headache_logs.recent_first }
      else
        broadcast_prepend_to [ user, "headache_logs" ], target: "headache_logs",
                                                       partial: "headache_logs/headache_log",
                                                       locals: { headache_log: self }
      end

      broadcast_update_stats
      broadcast_update_ongoing_headaches
      broadcast_update_charts
    end

    def broadcast_destroy
      broadcast_remove_to [ user, "headache_logs" ], target: self
      broadcast_remove_to [ user, "charts" ], target: self

      if user.headache_logs.count == 0
        broadcast_replace_to [ user, "headache_logs" ], target: "headache_logs",
                                                       partial: "headache_logs/logs_grid",
                                                       locals: { headache_logs: user.headache_logs.recent_first }
      end

      broadcast_update_stats
      broadcast_update_ongoing_headaches
      broadcast_update_charts
    end

    def broadcast_update
      broadcast_replace_to [ user, "headache_logs" ], target: self,
                                                     partial: "headache_logs/headache_log",
                                                     locals: { headache_log: self }

      broadcast_replace_to [ user, "charts" ], target: self,
                                              partial: "headache_logs/headache_log",
                                              locals: { headache_log: self }

      broadcast_update_stats
      broadcast_update_ongoing_headaches
      broadcast_update_charts
    end

    def broadcast_update_charts
      headache_logs = user.headache_logs.chronological

      broadcast_replace_to [ user, "charts" ],
                           target: "charts",
                           partial: "charts/charts_frame",
                           locals: { headache_logs: headache_logs, chart_data: headache_logs.chart_data }
    end

    def broadcast_update_ongoing_headaches
      broadcast_replace_to [ user, "headache_logs" ], target: "ongoing_headaches",
                                                     partial: "headache_logs/ongoing_headaches",
                                                     locals: { current_user: user }

      broadcast_replace_to [ user, "charts" ], target: "ongoing_headaches",
                                              partial: "headache_logs/ongoing_headaches",
                                              locals: { current_user: user }

      broadcast_replace_to [ user, "application" ], target: "ongoing_headaches",
                                                   partial: "headache_logs/ongoing_headaches",
                                                   locals: { current_user: user }
    end

    def broadcast_update_stats
      broadcast_replace_to [ user, "headache_logs" ], target: "headache_stats",
                                                     partial: "headache_logs/stats",
                                                     locals: { current_user: user }

      broadcast_replace_to [ user, "charts" ], target: "headache_stats",
                                              partial: "headache_logs/stats",
                                              locals: { current_user: user }
    end
end
