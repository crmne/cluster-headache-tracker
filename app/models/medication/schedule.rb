# How often a medication is meant to be taken. "as_needed" (the default)
# covers abortives and oxygen; the rest describe preventives, from
# lithium twice a day to Botox once a quarter. Times of day are
# deliberately not modelled: people take their doses whenever their day
# allows, so adherence is judged per day (daily schedules) or per dosing
# interval (weekly and longer).
module Medication::Schedule
  extend ActiveSupport::Concern

  DOSES_PER_DAY = { "once_daily" => 1, "twice_daily" => 2, "three_times_daily" => 3 }.freeze
  INTERVALS = { "weekly" => 1.week, "monthly" => 1.month, "quarterly" => 3.months }.freeze
  FREQUENCIES = [ "as_needed", *DOSES_PER_DAY.keys, *INTERVALS.keys ].freeze
  DUE_SOON_WINDOW = 3.days

  included do
    enum :frequency, FREQUENCIES.index_by(&:itself), validate: true

    scope :scheduled, -> { where.not(frequency: "as_needed") }
  end

  def scheduled?
    !as_needed?
  end

  def daily?
    DOSES_PER_DAY.key?(frequency)
  end

  def doses_per_day
    DOSES_PER_DAY[frequency]
  end

  def dosing_interval
    INTERVALS[frequency]
  end

  def last_taken_at
    doses.maximum(:taken_at)
  end

  def next_due_at
    if dosing_interval && (last = last_taken_at)
      last + dosing_interval
    end
  end

  def doses_taken_today
    doses.where(taken_at: Time.current.all_day).count
  end

  # Whether to nudge on the dashboard: a daily preventive with doses still
  # to take today, or a long-interval one that is due within a few days.
  def due?
    if archived?
      false
    elsif daily?
      doses_taken_today < doses_per_day
    elsif next_due = next_due_at
      next_due <= DUE_SOON_WINDOW.from_now
    else
      false
    end
  end

  # Share of the given days on which this medication was taken as
  # scheduled: for daily schedules each day counts up to its doses per
  # day; for interval schedules a day counts when a dose was taken within
  # the preceding interval. Days before the first dose are ignored. Returns
  # nil when no day qualifies.
  def coverage_on(day, taken_dates)
    if daily?
      [ taken_dates.count(day).fdiv(doses_per_day), 1.0 ].min
    elsif dosing_interval
      taken_dates.any? { |date| date <= day && date + dosing_interval > day } ? 1.0 : 0.0
    end
  end
end
