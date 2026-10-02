require "csv"

class HeadacheLog < ApplicationRecord
  CSV_HEADERS = %w[ start_time end_time intensity medication triggers notes barometric_pressure ].freeze
  BAROMETRIC_PRESSURE_RANGE = 870..1085
  PRESSURE_BAND_WIDTH = 5
  PRESSURE_CHANGE_WINDOW = 24.hours

  belongs_to :user, counter_cache: true

  validates :start_time, :intensity, presence: true
  validates :intensity, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }
  validates :barometric_pressure, numericality: { in: BAROMETRIC_PRESSURE_RANGE }, allow_nil: true

  normalizes :medication, with: ->(value) { value.downcase.split(",").map(&:strip).reject(&:blank?).join(", ") }
  normalizes :triggers, with: ->(value) { value.split(",").map(&:strip).reject(&:blank?).join(", ") }

  after_create_commit :broadcast_create
  after_update_commit :broadcast_update
  after_destroy_commit :broadcast_destroy

  scope :chronological, -> { order(:start_time) }
  scope :recent_first, -> { order(start_time: :desc) }
  scope :ongoing, -> { where(end_time: nil) }
  scope :today, -> { where(start_time: Time.current.all_day) }
  scope :started_after, ->(start_time) { where("start_time >= ?", Date.parse(start_time).beginning_of_day) }
  scope :ended_before, ->(end_time) { where("end_time <= ? OR end_time IS NULL", Date.parse(end_time).end_of_day) }
  scope :with_triggers, ->(triggers) { where("triggers ILIKE ?", "%#{sanitize_sql_like(triggers)}%") }
  scope :with_medication, ->(medication) { where("medication ILIKE ?", "%#{sanitize_sql_like(medication)}%") }

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
      chart_data_for(chronological)
    end

    def chart_data_for(headache_logs)
      {
        intensity_data: intensity_data_for(headache_logs),
        trigger_data: trigger_data_for(headache_logs),
        medication_data: medication_data_for(headache_logs),
        hourly_data: hourly_data_for(headache_logs),
        attacks_per_day_data: attacks_per_day_data_for(headache_logs),
        duration_data: duration_data_for(headache_logs),
        pressure_data: pressure_data_for(headache_logs),
        pressure_change_data: pressure_change_data_for(headache_logs)
      }
    end

    def cycles(today: Current.today)
      Cycles.new(all, today: today)
    end

    def report(**options)
      Report.new(all, **options)
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << CSV_HEADERS

        recent_first.each do |log|
          csv << [
            log.start_time.strftime("%Y-%m-%d %H:%M:%S"),
            log.end_time&.strftime("%Y-%m-%d %H:%M:%S"),
            log.intensity.to_s,
            log.medication.to_s,
            log.triggers.to_s,
            log.notes.to_s,
            log.barometric_pressure&.to_s("F")
          ]
        end
      end
    end

    def import_csv(file:, user:)
      contents = File.read(file.path, encoding: "bom|utf-8")

      if migraine_buddy_export = MigraineBuddyExport.parse(contents)
        import_logs migraine_buddy_export.log_attributes, format: :migraine_buddy, user: user
      else
        import_logs native_log_attributes_from(contents), format: :cluster_headache_tracker, user: user
      end
    end

    def sample_logs
      base_date = Date.current - 18.days

      [
        sample_log(base_date, "02:10", "02:55", 8, "oxygen 15 min", "sleep disruption", "Right eye pain, paced during attack, relief after oxygen."),
        sample_log(base_date + 1.day, "01:42", "02:34", 9, "oxygen 20 min", "sleep disruption", "Woke from sleep, tearing, restless, shadow remained after relief."),
        sample_log(base_date + 3.days, "22:18", "22:56", 7, "sumatriptan", "alcohol", "Late evening attack after alcohol exposure, relief after medication."),
        sample_log(base_date + 5.days, "03:05", "04:12", 10, "oxygen 25 min", "sleep disruption", "Severe right-sided attack, oxygen helped but relief was slower."),
        sample_log(base_date + 6.days, "13:24", "13:58", 6, "oxygen 12 min", "none noted", "Shorter daytime attack, returned to work after relief."),
        sample_log(base_date + 8.days, "00:38", "01:29", 8, "oxygen 18 min", "sleep disruption", "Woke from sleep, nasal congestion, relief after oxygen."),
        sample_log(base_date + 10.days, "02:48", "03:31", 9, "oxygen 20 min", "sleep disruption", "Pacing and tearing, no medication side effects noted."),
        sample_log(base_date + 12.days, "21:16", "22:04", 7, "sumatriptan", "weather change", "Evening attack, medication helped within the hour."),
        sample_log(base_date + 13.days, "04:12", "04:49", 8, "oxygen 15 min", "sleep disruption", "Oxygen relief, mild shadow afterward."),
        sample_log(base_date + 15.days, "01:08", "02:02", 9, "oxygen 20 min", "sleep disruption", "Typical overnight pattern, attack ended after oxygen.")
      ].tap do |logs|
        # The marketing sample report feeds these unsaved logs through the
        # same stats partial as real reports, so quack like a relation.
        def logs.today = select { |log| log.start_time.today? }
        def logs.average(attribute) = sum(&attribute) / size.to_f
        def logs.cycles = HeadacheLog::Cycles.new(self)
      end
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

      def import_logs(logs_attributes, format:, user:)
        ImportResult.new(format: format).tap do |result|
          logs_attributes.each do |attributes|
            result.record import_log(attributes, user)
          end
        end
      end

      def import_log(attributes, user)
        if attributes.nil?
          :invalid
        elsif user.headache_logs.exists?(start_time: attributes[:start_time])
          :duplicate
        elsif user.headache_logs.create(attributes).persisted?
          :imported
        else
          :invalid
        end
      end

      def import_attributes_from(row)
        {
          start_time: parse_time(row[:start_time]),
          end_time: parse_time(row[:end_time]),
          intensity: row[:intensity],
          medication: row[:medication],
          triggers: row[:triggers],
          notes: row[:notes],
          barometric_pressure: row[:barometric_pressure]
        }
      end

      def intensity_data_for(logs)
        logs.map { |log| { x: log.start_time.iso8601, y: log.intensity } }
      end

      def medication_data_for(logs)
        medication_counts = Hash.new(0)

        logs.each do |log|
          medications = log.medication_list.map(&:downcase)

          medications.each do |medication|
            medication_counts[medication] += 1 unless medication.blank?
          end
        end

        medication_counts.sort_by { |_, count| -count }.first(5).to_h
      end

      def native_log_attributes_from(contents)
        CSV.parse(contents, headers: true, header_converters: :symbol).map do |row|
          import_attributes_from(row)
        rescue ArgumentError
          nil
        end
      end

      def parse_time(time_string)
        if time_string.present?
          Time.zone.parse(time_string)
        end
      end

      def pressure_data_for(logs)
        bands = logs.select(&:barometric_pressure).group_by { |log| pressure_band_for(log.barometric_pressure) }

        if bands.any?
          (bands.keys.min..bands.keys.max).step(PRESSURE_BAND_WIDTH).map do |band|
            band_logs = bands.fetch(band, [])

            {
              label: "#{band}–#{band + PRESSURE_BAND_WIDTH}",
              frequency: band_logs.size,
              avg_intensity: band_logs.any? ? (band_logs.sum(&:intensity).to_f / band_logs.size).round(2) : 0
            }
          end
        else
          []
        end
      end

      def pressure_band_for(pressure)
        (pressure / PRESSURE_BAND_WIDTH).floor * PRESSURE_BAND_WIDTH
      end

      def pressure_change_data_for(logs)
        readings = logs.select(&:barometric_pressure).sort_by(&:start_time)

        readings.each_cons(2).filter_map do |previous, log|
          elapsed = log.start_time - previous.start_time

          if elapsed <= PRESSURE_CHANGE_WINDOW
            {
              x: log.start_time.iso8601,
              y: (log.barometric_pressure - previous.barometric_pressure).to_f.round(1),
              pressure: log.barometric_pressure.to_f,
              hours: (elapsed / 1.hour).round(1),
              intensity: log.intensity
            }
          end
        end
      end

      def sample_log(date, start_time, end_time, intensity, medication, triggers, notes)
        new(
          start_time: Time.zone.parse("#{date} #{start_time}"),
          end_time: Time.zone.parse("#{date} #{end_time}"),
          intensity: intensity,
          medication: medication,
          triggers: triggers,
          notes: notes
        )
      end

      def trigger_data_for(logs)
        trigger_counts = Hash.new(0)

        logs.each do |log|
          triggers = log.trigger_list

          triggers.each do |trigger|
            trigger_counts[trigger] += 1 unless trigger.blank?
          end
        end

        trigger_counts.sort_by { |_, count| -count }.first(5).to_h
      end
  end

  def duration
    if end_time
      end_time - start_time
    end
  end

  def medication_list = medication.to_s.split(",").map(&:strip)
  def trigger_list = triggers.to_s.split(",").map(&:strip)

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
      headache_logs = user.headache_logs.order(start_time: :desc)

      [ [ user, "headache_logs" ], [ user, "charts" ] ].each do |stream|
        # The channel-level API passes only these locals, satisfying the
        # partial's strict locals (instance-level broadcasts would merge
        # in a headache_log local).
        Turbo::StreamsChannel.broadcast_replace_to stream, target: "headache_stats",
                                                           partial: "headache_logs/stats",
                                                           locals: { headache_logs: headache_logs }
      end
    end
end
