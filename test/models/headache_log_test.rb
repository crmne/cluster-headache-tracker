require "test_helper"

class HeadacheLogTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @headache_log = HeadacheLog.new(
      user: @user,
      start_time: Time.current,
      intensity: 5,
      medication: "Sumatriptan",
      triggers: "Lack of sleep"
    )
  end

  test "should be valid" do
    assert @headache_log.valid?
  end

  test "user id should be present" do
    @headache_log.user_id = nil
    assert_not @headache_log.valid?
  end

  test "start time should be present" do
    @headache_log.start_time = nil
    assert_not @headache_log.valid?
  end

  test "intensity should be present" do
    @headache_log.intensity = nil
    assert_not @headache_log.valid?
  end

  test "intensity should be between 1 and 10" do
    @headache_log.intensity = 0
    assert_not @headache_log.valid?

    @headache_log.intensity = 11
    assert_not @headache_log.valid?

    @headache_log.intensity = 5
    assert @headache_log.valid?
  end

  test "should filter by date range" do
    log = headache_logs(:one)
    log_date = log.start_time.to_date

    filtered_logs = HeadacheLog.filter_by_params({
      start_time: log_date - 1.day,
      end_time: log_date + 1.day
    })

    assert_includes filtered_logs, log
    assert filtered_logs.all? { |l| l.start_time >= (log_date - 1.day).beginning_of_day }
    assert filtered_logs.all? { |l| l.start_time <= (log_date + 1.day).end_of_day }
  end

  test "should filter by triggers" do
    filtered_logs = HeadacheLog.filter_by_params({ triggers: "Sleeping" })
    assert filtered_logs.all? { |log| log.triggers&.include?("Sleeping") }
  end

  test "should filter by medication" do
    filtered_logs = HeadacheLog.filter_by_params({ medication: "Sumatriptan" })
    assert filtered_logs.all? { |log| log.medication&.include?("Sumatriptan") }
  end
end
