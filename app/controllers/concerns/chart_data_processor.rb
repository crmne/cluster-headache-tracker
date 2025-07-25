module ChartDataProcessor
  extend ActiveSupport::Concern

  def process_chart_data(headache_logs)
    {
      intensity_data: process_intensity_data(headache_logs),
      trigger_data: process_trigger_data(headache_logs),
      medication_data: process_medication_data(headache_logs),
      hourly_data: process_hourly_data(headache_logs),
      attacks_per_day_data: process_attacks_per_day_data(headache_logs),
      duration_data: process_duration_data(headache_logs)
    }
  end

  private

  def process_intensity_data(logs)
    logs.map { |log| { x: log.start_time.iso8601, y: log.intensity } }
  end

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
      medications = log.medication.to_s.split(",").map(&:strip).map(&:downcase)
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

  def process_attacks_per_day_data(logs)
    attacks_per_day = logs.group_by { |log| log.start_time.to_date }
                          .transform_values(&:count)

    attacks_per_day.map { |date, count| { x: date.iso8601, y: count } }
  end

  def process_duration_data(logs)
    # Only include logs that have both start and end times
    complete_logs = logs.reject { |log| log.end_time.nil? }

    # Calculate durations in hours
    complete_logs.map do |log|
      duration_hours = ((log.end_time - log.start_time) / 1.hour).round(2)  # More precision for short durations
      {
        x: log.start_time.iso8601,  # Ensure proper date format for JavaScript
        y: duration_hours,
        intensity: log.intensity # Include intensity for potential correlation analysis
      }
    end
  end
end
