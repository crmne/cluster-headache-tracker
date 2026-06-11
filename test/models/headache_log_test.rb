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
    included_log = headache_logs(:one)
    start_date = included_log.start_time.to_date
    end_date = start_date + 1.day
    filtered_logs = HeadacheLog.filtered_by({
      start_time: start_date.to_s,
      end_time: end_date.to_s
    })

    assert_includes filtered_logs, included_log
    assert filtered_logs.all? { |l| l.start_time.to_date >= start_date }
    assert filtered_logs.all? { |l| l.start_time.to_date <= end_date }
  end

  test "should filter by triggers" do
    filtered_logs = HeadacheLog.filtered_by({ triggers: "Sleeping" })
    assert_includes filtered_logs, headache_logs(:one)
    assert_not_includes filtered_logs, headache_logs(:two)
  end

  test "should filter by medication" do
    filtered_logs = HeadacheLog.filtered_by({ medication: "Sumatriptan" })
    assert_includes filtered_logs, headache_logs(:two)
    assert_not_includes filtered_logs, headache_logs(:one)
  end

  test "chart_data buckets attacks into two-hour windows with average intensity" do
    logs = [
      chart_log(start_time: "2024-03-01 03:30", intensity: 6),
      chart_log(start_time: "2024-03-02 02:10", intensity: 8)
    ]

    bucket = HeadacheLog.chart_data_for(logs)[:hourly_data][1]

    assert_equal "2:00 - 3:59", bucket[:label]
    assert_equal 2, bucket[:frequency]
    assert_equal 7.0, bucket[:avg_intensity]
  end

  test "chart_data rounds durations to hundredths and skips ongoing attacks" do
    logs = [
      chart_log(start_time: "2024-03-01 01:00", end_time: "2024-03-01 02:40", intensity: 7),
      chart_log(start_time: "2024-03-02 01:00", intensity: 5)
    ]

    duration_data = HeadacheLog.chart_data_for(logs)[:duration_data]

    assert_equal 1, duration_data.size
    assert_equal 1.67, duration_data.first[:y]
    assert_equal 7, duration_data.first[:intensity]
  end

  test "chart_data counts attacks per day" do
    logs = [
      chart_log(start_time: "2024-03-01 01:00"),
      chart_log(start_time: "2024-03-01 22:00"),
      chart_log(start_time: "2024-03-02 01:00")
    ]

    attacks_per_day = HeadacheLog.chart_data_for(logs)[:attacks_per_day_data]

    assert_equal [ { x: "2024-03-01", y: 2 }, { x: "2024-03-02", y: 1 } ], attacks_per_day
  end

  test "chart_data splits medications on commas and keeps the top five" do
    logs = [
      chart_log(medication: "oxygen, sumatriptan"),
      chart_log(medication: "oxygen"),
      chart_log(medication: "verapamil, prednisone, lithium, melatonin")
    ]

    medication_data = HeadacheLog.chart_data_for(logs)[:medication_data]

    assert_equal 5, medication_data.size
    assert_equal 2, medication_data["oxygen"]
    assert_equal 1, medication_data["sumatriptan"]
  end

  private
    def chart_log(start_time: "2024-03-01 12:00", end_time: nil, intensity: 5, medication: nil)
      HeadacheLog.new(
        user: @user,
        start_time: Time.zone.parse(start_time),
        end_time: end_time && Time.zone.parse(end_time),
        intensity: intensity,
        medication: medication
      )
    end
end
