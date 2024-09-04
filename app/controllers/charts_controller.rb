class ChartsController < ApplicationController
  before_action :authenticate_user!

  def index
    @headache_logs = current_user.headache_logs.filter_by_params(params).order(:start_time)

    @intensity_data = @headache_logs.map { |log| { x: log.start_time, y: log.intensity } }

    @trigger_data = process_trigger_data(@headache_logs)
    @medication_data = process_medication_data(@headache_logs)
    @hourly_data = process_hourly_data(@headache_logs)
    @attacks_per_day_data = HeadacheLog.process_attacks_per_day_data(@headache_logs)
  end

  private

  def process_trigger_data(logs)
    trigger_counts = Hash.new(0)
    logs.each do |log|
      triggers = log.triggers.to_s.split(",").map(&:strip)
      triggers.each { |trigger| trigger_counts[trigger] += 1 unless trigger.blank? }
    end

    trigger_counts.sort_by { |_, count| -count }.first(5).to_h
  end

  def process_medication_data(logs)
    medication_counts = Hash.new(0)
    logs.each do |log|
      medications = log.medication.to_s.split("+").map(&:strip).map(&:downcase)
      medications.each { |med| medication_counts[med] += 1 unless med.blank? }
    end

    medication_counts.sort_by { |_, count| -count }.first(5).to_h
  end

  def process_hourly_data(logs)
    hourly_data = Array.new(12) { { count: 0, total_intensity: 0 } }

    logs.each do |log|
      hour = log.start_time.hour
      interval = hour / 2
      hourly_data[interval][:count] += 1
      hourly_data[interval][:total_intensity] += log.intensity
    end

    hourly_data.map.with_index do |data, index|
      start_hour = index * 2
      {
        label: "#{start_hour}:00 - #{start_hour + 1}:59",
        frequency: data[:count],
        avg_intensity: data[:count] > 0 ? (data[:total_intensity].to_f / data[:count]).round(2) : 0
      }
    end
  end
end
