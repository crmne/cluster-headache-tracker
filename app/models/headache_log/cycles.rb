# Attack days, attack-free streaks and cluster cycles for a set of headache logs.
#
# Day boundaries. Start and end times are stored as the wall-clock time the
# patient entered (the app runs in UTC and datetime-local fields carry no
# offset), so their calendar date already is the patient's local day. Only
# "today" depends on where the patient is right now, which is why it comes from
# Current.today (the time zone their browser reports).
#
# Attack days. Every calendar day an attack touched. An attack that runs past
# midnight makes both days attack days, but it is never stretched further than
# that, so a log someone forgot to end can't paint weeks of pain. An ongoing
# attack counts its start day and keeps the current streak at zero.
#
# Cycles. Attack days belong to the same cycle (cluster period, or bout) until
# the patient goes REMISSION_THRESHOLD attack-free days in a row. ICHD-3 only
# calls it remission after at least three months pain-free (3.1.1 episodic
# cluster headache). That is too long to tell a bout ended while you are still
# tracking it, and it would fold every bout of a chronic patient into one. Two
# weeks is long enough that a lull of a few days inside a bout (common under
# preventive treatment) doesn't split it, and short enough to show the bout
# ended without waiting a season. Gaps between cycles that do meet the ICHD-3
# three-month definition are flagged, so doctors can tell episodic from chronic.
class HeadacheLog::Cycles
  include Enumerable

  REMISSION_THRESHOLD = 14 # attack-free days
  ICHD_REMISSION_MONTHS = 3

  Attack = Data.define(:start_time, :end_time, :intensity) do
    def start_on = start_time.to_date

    def days
      if end_time && end_time.to_date > start_on
        [ start_on, start_on.next_day ]
      else
        [ start_on ]
      end
    end

    def ongoing? = end_time.nil?
  end

  Cycle = Data.define(:start_on, :end_on, :attack_count, :total_intensity, :ongoing) do
    def length_in_days = (end_on - start_on).to_i + 1

    def average_intensity
      if attack_count.positive?
        total_intensity.fdiv(attack_count).round(1)
      end
    end

    def ongoing? = ongoing
  end

  Remission = Data.define(:start_on, :end_on) do
    def length_in_days = (end_on - start_on).to_i + 1
    def ichd_remission? = start_on.advance(months: ICHD_REMISSION_MONTHS) <= end_on.next_day
  end

  attr_reader :today, :remission_threshold

  def initialize(headache_logs, today: Current.today, remission_threshold: REMISSION_THRESHOLD)
    @attacks = headache_logs.pluck(:start_time, :end_time, :intensity).map { |values| Attack.new(*values) }
    @today = today
    @remission_threshold = remission_threshold
  end

  def each(&) = cycles.each(&)
  def size = cycles.size
  def last = cycles.last

  # How many attacks touched each day, for the calendar heatmap.
  def attack_counts_by_day
    @attack_counts_by_day ||= @attacks.each_with_object(Hash.new(0)) do |attack, counts|
      attack.days.each { |day| counts[day] += 1 }
    end
  end

  def attack_days
    @attack_days ||= attack_counts_by_day.keys.sort
  end

  def total_attack_days = attack_days.size
  def first_attack_day = attack_days.first
  def last_attack_day = attack_days.last

  def ongoing_attack?
    @attacks.any?(&:ongoing?)
  end

  # Days since the last attack day, so 0 when there was an attack today.
  def current_streak
    if ongoing_attack?
      0
    elsif last_attack_day
      [ (today - last_attack_day).to_i, 0 ].max
    end
  end

  def longest_streak
    if any?
      gaps = attack_days.each_cons(2).map { |day, next_day| (next_day - day).to_i - 1 }
      [ *gaps, current_streak ].max
    end
  end

  def current_cycle
    last if last&.ongoing?
  end

  def remissions
    @remissions ||= cycles.each_cons(2).map do |cycle, next_cycle|
      Remission.new(start_on: cycle.end_on.next_day, end_on: next_cycle.start_on.prev_day)
    end
  end

  # The remission that came right before the given cycle, if any.
  def remission_before(cycle)
    if index = cycles.index(cycle)
      remissions[index - 1] if index.positive?
    end
  end

  def average_cycle_length
    average_length_of cycles
  end

  def average_remission_length
    average_length_of remissions
  end

  private
    def cycles
      @cycles ||= attack_days
        .slice_when { |day, next_day| (next_day - day).to_i > remission_threshold }
        .map { |days| cycle_from(days) }
    end

    def cycle_from(days)
      attacks = days.flat_map { |day| attacks_by_start_day.fetch(day, []) }

      Cycle.new \
        start_on: days.first,
        end_on: days.last,
        attack_count: attacks.size,
        total_intensity: attacks.sum(&:intensity),
        ongoing: days.last == last_attack_day && (ongoing_attack? || (today - days.last).to_i <= remission_threshold)
    end

    def attacks_by_start_day
      @attacks_by_start_day ||= @attacks.group_by(&:start_on)
    end

    def average_length_of(periods)
      if periods.any?
        periods.sum(&:length_in_days).fdiv(periods.size).round(1)
      end
    end
end
