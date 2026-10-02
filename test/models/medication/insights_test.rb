require "test_helper"

class Medication::InsightsTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.medication_doses.delete_all
    @user.headache_logs.destroy_all
    @today = Date.current
  end

  test "success rate, severe-attack success rate and average time to relief per medication" do
    rate :oxygen, "helped", intensity: 9, relief: 10
    rate :oxygen, "helped", intensity: 6, relief: 20
    rate :oxygen, "no_effect", intensity: 8
    rate :sumatriptan, "made_worse", intensity: 5
    rate :sumatriptan, nil, intensity: 5

    oxygen = summary_for(:oxygen)
    assert_equal [ 3, 3, 2, 1, 0 ], oxygen.to_h.values_at(:doses_count, :rated_count, :helped_count, :no_effect_count, :made_worse_count)
    assert_equal 67, oxygen.success_rate
    assert_equal 50, oxygen.severe_success_rate
    assert_equal 15, oxygen.average_minutes_to_relief

    sumatriptan = summary_for(:sumatriptan)
    assert_equal 0, sumatriptan.success_rate
    assert_nil sumatriptan.severe_success_rate
    assert_nil sumatriptan.average_minutes_to_relief
  end

  test "only rates doses taken for the given attacks" do
    rate :oxygen, "helped", intensity: 9
    other = rate(:oxygen, "no_effect", intensity: 9)

    insights = Medication::Insights.new(user: @user, headache_logs: @user.headache_logs.where.not(id: other.headache_log_id))

    assert_equal 100, insights.summaries.find { |summary| summary.medication == medications(:oxygen) }.success_rate
  end

  test "leaves out medications without doses" do
    rate :oxygen, "helped", intensity: 9

    assert_equal [ medications(:oxygen) ], insights.summaries.map(&:medication)
  end

  test "weekly preventive adherence next to attacks per week" do
    lithium = medications(:lithium)
    week = @today.beginning_of_week - 1.week

    # Monday: both doses, Tuesday: one, rest of the week: none
    take lithium, week, week, week + 1.day
    attack_on week + 2.days
    attack_on week + 3.days

    insights = insights(from: week, to: week + 6.days)
    first_week = insights.adherence_by_week.first

    assert_equal week.iso8601, first_week[:x]
    assert_equal 2, first_week[:attacks]
    assert_equal 21, first_week[:adherence] # (1 + 0.5 + 5 × 0) / 7 days
    assert_equal 21, insights.summaries.find { |summary| summary.medication == lithium }.adherence
  end

  test "a monthly injection covers the weeks after it, even when given before the period" do
    emgality = medications(:emgality)
    take emgality, @today - 50.days

    insights = insights(from: @today - 13.days, to: @today)

    assert insights.adherence_by_week?
    assert_equal 0, insights.summaries.find { |summary| summary.medication == emgality }.adherence

    take emgality, @today - 13.days
    insights = insights(from: @today - 13.days, to: @today)
    summary = insights.summaries.find { |summary| summary.medication == emgality }

    assert_equal 100, summary.adherence
    assert_equal [ @today - 13.days ], summary.dates
  end

  test "days before the first dose don't count against adherence" do
    lithium = medications(:lithium)
    take lithium, @today, @today

    assert_equal 100, insights(from: @today - 30.days, to: @today).summaries.find { |summary| summary.medication == lithium }.adherence
  end

  test "without scheduled preventives there is no adherence chart" do
    medications(:lithium).update!(frequency: "as_needed")
    medications(:emgality).update!(frequency: "as_needed")

    assert_not insights.adherence_by_week?
  end

  private
    def insights(from: nil, to: nil)
      Medication::Insights.new(user: @user, headache_logs: @user.headache_logs, from: from, to: to)
    end

    def summary_for(name)
      insights.summaries.find { |summary| summary.medication == medications(name) }
    end

    def rate(name, effectiveness, intensity:, relief: nil)
      log = attack_on(@today - 3.days, intensity: intensity)
      log.medication_doses.create!(user: @user, medication: medications(name), taken_at: log.start_time + 5.minutes,
        effectiveness: effectiveness, minutes_to_relief: relief, skip_headache_log_refresh: true)
    end

    def attack_on(date, intensity: 7)
      @user.headache_logs.create!(start_time: date.to_time.change(hour: 2), end_time: date.to_time.change(hour: 3), intensity: intensity)
    end

    def take(medication, *dates)
      dates.each { |date| @user.medication_doses.create!(medication: medication, taken_at: date.to_time.change(hour: 9)) }
    end
end
