require "test_helper"

class HeadacheLog::CyclesTest < ActiveSupport::TestCase
  setup do
    @user = users(:carmine)
    @today = Date.new(2026, 10, 2)
  end

  test "no logs" do
    cycles = cycles_for

    assert_not cycles.any?
    assert_equal 0, cycles.size
    assert_equal 0, cycles.total_attack_days
    assert_nil cycles.current_streak
    assert_nil cycles.longest_streak
    assert_nil cycles.current_cycle
    assert_nil cycles.average_cycle_length
    assert_nil cycles.average_remission_length
    assert_empty cycles.remissions
    assert_not cycles.ongoing_attack?
  end

  test "current streak counts the days since the last attack day" do
    log_attack "2026-09-29 03:00", "2026-09-29 04:00"

    assert_equal 3, cycles_for.current_streak
  end

  test "an attack today means no attack-free days yet" do
    log_attack "2026-10-02 01:00", "2026-10-02 02:00"

    assert_equal 0, cycles_for.current_streak
  end

  test "attacks logged in the future don't make the streak negative" do
    log_attack "2026-10-05 01:00", "2026-10-05 02:00"

    assert_equal 0, cycles_for.current_streak
  end

  test "an ongoing attack keeps the streak at zero and the cycle open" do
    log_attack "2026-09-20 03:00", "2026-09-20 04:00"
    log_attack "2026-10-01 23:30", nil

    cycles = cycles_for

    assert cycles.ongoing_attack?
    assert_equal 0, cycles.current_streak
    assert cycles.current_cycle.ongoing?
    assert_equal [ Date.new(2026, 9, 20), Date.new(2026, 10, 1) ], cycles.attack_days
  end

  test "an attack spanning midnight makes both days attack days" do
    log_attack "2026-09-10 23:30", "2026-09-11 00:45", intensity: 8

    cycles = cycles_for

    assert_equal [ Date.new(2026, 9, 10), Date.new(2026, 9, 11) ], cycles.attack_days
    assert_equal 1, cycles.attack_counts_by_day[Date.new(2026, 9, 11)]
    assert_equal 21, cycles.current_streak
    assert_equal 1, cycles.first.attack_count
    assert_equal 2, cycles.first.length_in_days
  end

  test "an attack someone forgot to end only spans into the next day" do
    log_attack "2026-09-10 23:30", "2026-09-25 08:00"

    assert_equal [ Date.new(2026, 9, 10), Date.new(2026, 9, 11) ], cycles_for.attack_days
  end

  test "attack counts by day" do
    log_attack "2026-09-10 02:00", "2026-09-10 03:00"
    log_attack "2026-09-10 14:00", "2026-09-10 15:00"
    log_attack "2026-09-12 02:00", "2026-09-12 03:00"

    counts = cycles_for.attack_counts_by_day

    assert_equal 2, counts[Date.new(2026, 9, 10)]
    assert_equal 0, counts[Date.new(2026, 9, 11)]
    assert_equal 1, counts[Date.new(2026, 9, 12)]
    assert_equal 2, cycles_for.total_attack_days
  end

  test "longest streak is the longest run of attack-free days between attack days" do
    log_attack "2026-06-01 02:00", "2026-06-01 03:00"
    log_attack "2026-06-11 02:00", "2026-06-11 03:00"
    log_attack "2026-09-30 02:00", "2026-09-30 03:00"

    assert_equal 110, cycles_for.longest_streak
  end

  test "longest streak includes the current streak" do
    log_attack "2026-06-01 02:00", "2026-06-01 03:00"
    log_attack "2026-06-03 02:00", "2026-06-03 03:00"

    cycles = cycles_for

    assert_equal 121, cycles.current_streak
    assert_equal 121, cycles.longest_streak
  end

  test "one long cycle" do
    60.times do |day|
      log_attack (Time.zone.parse("2026-08-01 02:00") + day.days).to_s, (Time.zone.parse("2026-08-01 03:00") + day.days).to_s, intensity: day.even? ? 6 : 8
    end

    cycles = cycles_for

    assert_equal 1, cycles.size
    assert_equal Date.new(2026, 8, 1), cycles.first.start_on
    assert_equal Date.new(2026, 9, 29), cycles.first.end_on
    assert_equal 60, cycles.first.length_in_days
    assert_equal 60, cycles.first.attack_count
    assert_equal 7.0, cycles.first.average_intensity
    assert cycles.first.ongoing?
    assert_equal cycles.first, cycles.current_cycle
    assert_empty cycles.remissions
    assert_equal 60.0, cycles.average_cycle_length
    assert_nil cycles.average_remission_length
    assert_equal 60, cycles.total_attack_days
  end

  test "attack-free gaps shorter than the remission threshold stay in the same cycle" do
    log_attack "2026-07-01 02:00", "2026-07-01 03:00"
    log_attack "2026-07-15 02:00", "2026-07-15 03:00" # 13 attack-free days in between

    assert_equal 1, cycles_for.size
  end

  test "an attack-free gap as long as the remission threshold starts a new cycle" do
    log_attack "2026-07-01 02:00", "2026-07-01 03:00"
    log_attack "2026-07-16 02:00", "2026-07-16 03:00" # 14 attack-free days in between

    cycles = cycles_for

    assert_equal 2, cycles.size
    assert_equal 14, cycles.remissions.first.length_in_days
  end

  test "the remission threshold is configurable" do
    log_attack "2026-07-01 02:00", "2026-07-01 03:00"
    log_attack "2026-07-08 02:00", "2026-07-08 03:00"

    assert_equal 2, cycles_for(remission_threshold: 5).size
    assert_equal 1, cycles_for.size
  end

  test "cycles with their remissions and averages" do
    # First cycle: 10 days, 3 attacks
    log_attack "2026-01-01 02:00", "2026-01-01 03:00", intensity: 6
    log_attack "2026-01-05 02:00", "2026-01-05 03:00", intensity: 8
    log_attack "2026-01-10 02:00", "2026-01-10 03:00", intensity: 10
    # Second cycle after more than three months: 5 days, 2 attacks
    log_attack "2026-05-01 02:00", "2026-05-01 03:00", intensity: 5
    log_attack "2026-05-05 02:00", "2026-05-05 03:00", intensity: 6
    # Third cycle after a month: 1 day, 1 attack
    log_attack "2026-06-05 02:00", "2026-06-05 03:00", intensity: 9

    cycles = cycles_for
    first, second, third = cycles.to_a

    assert_equal 3, cycles.size

    assert_equal [ Date.new(2026, 1, 1), Date.new(2026, 1, 10) ], [ first.start_on, first.end_on ]
    assert_equal 10, first.length_in_days
    assert_equal 3, first.attack_count
    assert_equal 8.0, first.average_intensity
    assert_not first.ongoing?

    assert_equal 5, second.length_in_days
    assert_equal 2, second.attack_count
    assert_equal 5.5, second.average_intensity

    assert_equal 1, third.length_in_days
    assert_not third.ongoing?
    assert_nil cycles.current_cycle

    first_remission, second_remission = cycles.remissions
    assert_equal [ Date.new(2026, 1, 11), Date.new(2026, 4, 30) ], [ first_remission.start_on, first_remission.end_on ]
    assert_equal 110, first_remission.length_in_days
    assert first_remission.ichd_remission?
    assert_equal 30, second_remission.length_in_days
    assert_not second_remission.ichd_remission?

    assert_nil cycles.remission_before(first)
    assert_equal first_remission, cycles.remission_before(second)
    assert_equal second_remission, cycles.remission_before(third)

    assert_equal 5.3, cycles.average_cycle_length
    assert_equal 70.0, cycles.average_remission_length
  end

  test "a remission of exactly three months meets the ICHD-3 definition" do
    remission = HeadacheLog::Cycles::Remission.new(start_on: Date.new(2026, 1, 11), end_on: Date.new(2026, 4, 10))

    assert remission.ichd_remission?
    assert_not HeadacheLog::Cycles::Remission.new(start_on: Date.new(2026, 1, 11), end_on: Date.new(2026, 4, 9)).ichd_remission?
  end

  test "the last cycle stays ongoing until the remission threshold has passed" do
    log_attack "2026-09-18 02:00", "2026-09-18 03:00"

    @today = Date.new(2026, 10, 2)
    assert cycles_for.current_cycle, "the 14th attack-free day isn't over yet"

    @today = Date.new(2026, 10, 3)
    assert_nil cycles_for.current_cycle, "14 full attack-free days have passed"
  end

  test "today follows the patient's time zone" do
    log_attack "2026-10-02 01:00", "2026-10-02 02:00"

    travel_to Time.utc(2026, 10, 2, 20, 0) do
      assert_equal 0, @user.headache_logs.cycles.current_streak

      Current.set(time_zone: ActiveSupport::TimeZone["Pacific/Auckland"]) do
        assert_equal 1, @user.headache_logs.cycles.current_streak
      end
    end
  end

  test "works on a filtered relation" do
    log_attack "2026-09-01 02:00", "2026-09-01 03:00", triggers: "alcohol"
    log_attack "2026-09-20 02:00", "2026-09-20 03:00", triggers: "sleep"

    cycles = @user.headache_logs.with_triggers("alcohol").chronological.cycles(today: @today)

    assert_equal [ Date.new(2026, 9, 1) ], cycles.attack_days
  end

  test "works on unsaved sample logs" do
    cycles = HeadacheLog.sample_logs.cycles

    assert_equal 10, cycles.total_attack_days
    assert_equal 1, cycles.size
    assert_equal 10, cycles.first.attack_count
  end

  test "reads thousands of logs in a single query" do
    start = Time.zone.parse("2016-01-01 02:00")
    rows = 3_000.times.map do |index|
      started_at = start + (index * 1.3).round.days
      { user_id: @user.id, start_time: started_at, end_time: started_at + 1.hour, intensity: 5, created_at: Time.current, updated_at: Time.current }
    end
    HeadacheLog.insert_all rows

    assert_queries_count 1 do
      cycles = cycles_for

      assert_equal 3_000, cycles.total_attack_days
      assert_equal 1, cycles.size
      assert_equal 3_000, cycles.first.attack_count
      assert_equal cycles.current_streak, cycles.longest_streak
    end
  end

  private
    def log_attack(start_time, end_time, intensity: 7, triggers: nil)
      @user.headache_logs.create! \
        start_time: Time.zone.parse(start_time),
        end_time: end_time && Time.zone.parse(end_time),
        intensity: intensity,
        triggers: triggers
    end

    def cycles_for(**options)
      HeadacheLog::Cycles.new(@user.headache_logs, today: @today, **options)
    end
end
