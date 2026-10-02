# What a report says about medications for a set of (filtered) headache
# logs: how often each treatment helped the attacks it was taken for, how
# long relief took, and how consistently scheduled preventives were taken
# week by week next to the number of attacks in those weeks.
class Medication::Insights
  SEVERE_INTENSITY = 8
  MAX_WEEKS = 52

  Summary = Data.define(:medication, :doses_count, :rated_count, :helped_count, :no_effect_count, :made_worse_count,
    :severe_rated_count, :severe_helped_count, :average_minutes_to_relief, :adherence, :dates) do
    def success_rate = percentage(helped_count, rated_count)
    def severe_success_rate = percentage(severe_helped_count, severe_rated_count)
    def share_of(count) = percentage(count, rated_count)

    private
      def percentage(count, total)
        (count * 100.0 / total).round if total.positive?
      end
  end

  attr_reader :user, :headache_logs, :from, :to

  def initialize(user:, headache_logs:, from: nil, to: nil)
    @user = user
    @headache_logs = headache_logs
    @to = to || Date.current
    @from = [ from || first_dose_date || @to, @to - MAX_WEEKS.weeks ].max
  end

  def any?
    summaries.any?
  end

  def summaries
    @summaries ||= medications.filter_map do |medication|
      summary_for(medication) if reportable?(medication)
    end
  end

  def adherence_by_week?
    scheduled_medications.any? { |medication| taken_dates_for(medication).any? }
  end

  def adherence_by_week
    @adherence_by_week ||= weeks.map do |week|
      days = week.all_week.select { |day| day.between?(from, to) }

      {
        x: week.iso8601,
        attacks: attacks_per_week.fetch(week, 0),
        adherence: percentage_of(scheduled_medications.flat_map { |medication| coverage_for(medication, days) })
      }
    end
  end

  private
    def medications
      @medications ||= user.medications.alphabetically.to_a
    end

    # Taken in the period, or a scheduled preventive started before it, whose
    # missed doses are the point.
    def reportable?(medication)
      attack_doses_by_medication.key?(medication.id) || period_doses_by_medication.key?(medication.id) ||
        (scheduled_medications.include?(medication) && taken_dates_for(medication).any?)
    end

    def summary_for(medication)
      attack_doses = attack_doses_by_medication.fetch(medication.id, [])
      rated = attack_doses.select(&:effectiveness)
      severe = rated.select { |dose| dose.headache_log.intensity >= SEVERE_INTENSITY }
      relief_minutes = attack_doses.filter_map(&:minutes_to_relief)
      period_doses = period_doses_by_medication.fetch(medication.id, [])

      Summary.new \
        medication: medication,
        doses_count: (attack_doses | period_doses).size,
        rated_count: rated.size,
        helped_count: rated.count(&:helped?),
        no_effect_count: rated.count(&:no_effect?),
        made_worse_count: rated.count(&:made_worse?),
        severe_rated_count: severe.size,
        severe_helped_count: severe.count(&:helped?),
        average_minutes_to_relief: relief_minutes.any? ? (relief_minutes.sum.fdiv(relief_minutes.size)).round : nil,
        adherence: (percentage_of(coverage_for(medication, (from..to).to_a)) if medication.scheduled?),
        dates: (period_doses.map { |dose| dose.taken_at.to_date }.uniq.sort if medication.dosing_interval)
    end

    def attack_doses_by_medication
      @attack_doses_by_medication ||= MedicationDose
        .where(headache_log_id: headache_log_ids)
        .includes(:headache_log)
        .group_by(&:medication_id)
    end

    def headache_log_ids
      if headache_logs.respond_to?(:pluck)
        headache_logs.pluck(:id)
      else
        headache_logs.map(&:id)
      end
    end

    def period_doses_by_medication
      @period_doses_by_medication ||= user.medication_doses.taken_between(from, to).group_by(&:medication_id)
    end

    def scheduled_medications
      @scheduled_medications ||= medications.select(&:scheduled?)
    end

    def coverage_for(medication, days)
      taken_dates = taken_dates_for(medication)

      if first_taken = taken_dates.min
        last_day = medication.archived_at&.to_date || to
        days.select { |day| day.between?(first_taken, last_day) }.map { |day| medication.coverage_on(day, taken_dates) }
      else
        []
      end
    end

    # Includes doses from before the period, so a quarterly injection taken
    # two months earlier still covers its first weeks.
    def taken_dates_for(medication)
      @taken_dates ||= user.medication_doses
        .where(medication: scheduled_medications, taken_at: (from - 3.months).beginning_of_day..to.end_of_day)
        .pluck(:medication_id, :taken_at)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map { |_, taken_at| taken_at.to_date } }

      @taken_dates.fetch(medication.id, [])
    end

    def weeks
      (from.beginning_of_week..to).step(7).to_a
    end

    def attacks_per_week
      @attacks_per_week ||= headache_logs.map(&:start_time).map { |time| time.to_date.beginning_of_week }.tally
    end

    def first_dose_date
      user.medication_doses.minimum(:taken_at)&.to_date
    end

    def percentage_of(coverages)
      (coverages.sum * 100 / coverages.size).round if coverages.any?
    end
end
