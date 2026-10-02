class HeadacheLog::Report
  FILTERS = %i[ start_time end_time triggers medication ].freeze
  TIME_OF_DAY_BUCKET_HOURS = 2

  MedicationUsage = Data.define(:name, :attacks, :average_duration)

  attr_reader :headache_logs, :patient_name, :prepared_for, :filters

  def initialize(headache_logs, patient_name: nil, prepared_for: nil, filters: {})
    @headache_logs = headache_logs.reorder(:start_time).to_a
    @patient_name = clean(patient_name)
    @prepared_for = clean(prepared_for)
    @filters = filters.to_h.symbolize_keys.slice(*FILTERS).compact_blank
  end

  def to_pdf
    Pdf.new(self).render
  end

  def filename
    "#{I18n.t("pdf_reports.filename")}-#{Date.current.iso8601}.pdf"
  end

  def period
    first_day = filter_date(:start_time) || headache_logs.first&.start_time&.to_date
    last_day = filter_date(:end_time) || headache_logs.last&.start_time&.to_date || Date.current

    if first_day
      Range.new(*[ first_day, last_day ].minmax)
    end
  end

  def attack_count
    headache_logs.size
  end

  def attack_days
    headache_logs.map { |log| log.start_time.to_date }.uniq.size
  end

  def average_intensity
    if headache_logs.any?
      headache_logs.sum(&:intensity).fdiv(attack_count)
    end
  end

  def max_intensity
    headache_logs.map(&:intensity).max
  end

  def average_duration
    average_duration_of(headache_logs)
  end

  def attacks_per_day
    attacks_by_day = headache_logs.map { |log| log.start_time.to_date }.tally

    period.to_h { |day| [ day, attacks_by_day.fetch(day, 0) ] }
  end

  def attacks_by_time_of_day
    buckets = Array.new(24 / TIME_OF_DAY_BUCKET_HOURS, 0)

    headache_logs.each { |log| buckets[log.start_time.hour / TIME_OF_DAY_BUCKET_HOURS] += 1 }

    buckets
  end

  def medication_usage
    headache_logs
      .flat_map { |log| log.medication_list.map { |medication| [ medication, log ] } }
      .group_by(&:first)
      .map { |medication, entries| usage_for(medication, entries.map(&:last)) }
      .sort_by { |usage| [ -usage.attacks, usage.name ] }
  end

  def trigger_counts
    headache_logs.flat_map(&:trigger_list).compact_blank.tally.sort_by { |trigger, count| [ -count, trigger ] }
  end

  private
    def clean(value)
      value.to_s.squish.first(100).presence
    end

    def filter_date(key)
      if filters[key]
        Date.parse(filters[key])
      end
    end

    def average_duration_of(logs)
      durations = logs.filter_map(&:duration)

      if durations.any?
        durations.sum / durations.size
      end
    end

    def usage_for(medication, logs)
      MedicationUsage.new(name: medication, attacks: logs.uniq.size, average_duration: average_duration_of(logs.uniq))
    end
end
