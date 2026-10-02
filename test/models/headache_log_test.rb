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

  test "import_csv imports the contributed Migraine Buddy sample" do
    result = nil

    assert_difference -> { @user.headache_logs.count }, 1 do
      result = HeadacheLog.import_csv(file: csv_fixture("migraine_buddy_sample.csv"), user: @user)
    end

    assert_equal :migraine_buddy, result.format
    assert_equal 1, result.imported
    assert_equal 0, result.skipped

    log = @user.headache_logs.find_by!(start_time: Time.zone.parse("2024-11-16 13:12 UTC"))
    assert_equal Time.zone.parse("2024-11-16 14:12 UTC"), log.end_time
    assert_equal 4, log.intensity
    assert_equal "", log.medication
    assert_equal "Stress", log.triggers
    assert_match "Symptoms: Sensitivity to light, Throbbing pain", log.notes
  end

  test "import_csv imports readable Migraine Buddy rows and skips malformed ones" do
    result = HeadacheLog.import_csv(file: csv_fixture("migraine_buddy_mixed.csv"), user: @user)

    assert_equal :migraine_buddy, result.format
    assert_equal 4, result.imported
    assert_equal 0, result.duplicates
    assert_equal 3, result.invalid

    log = @user.headache_logs.find_by!(start_time: Time.zone.parse("2024-11-16 12:12 UTC"))
    assert_equal "oxygen, sumatriptan, ibuprofen", log.medication
    assert_equal "Alcohol, Sleep", log.triggers
  end

  test "import_csv skips Migraine Buddy attacks that were already imported" do
    HeadacheLog.import_csv(file: csv_fixture("migraine_buddy_mixed.csv"), user: @user)
    result = nil

    assert_no_difference -> { @user.headache_logs.count } do
      result = HeadacheLog.import_csv(file: csv_fixture("migraine_buddy_mixed.csv"), user: @user)
    end

    assert_equal 0, result.imported
    assert_equal 4, result.duplicates
    assert_equal 3, result.invalid
  end

  test "import_csv only skips attacks the same user already logged" do
    HeadacheLog.import_csv(file: csv_fixture("migraine_buddy_sample.csv"), user: users(:two))

    assert_difference -> { @user.headache_logs.count }, 1 do
      HeadacheLog.import_csv(file: csv_fixture("migraine_buddy_sample.csv"), user: @user)
    end
  end

  test "import_csv reads the app's own export and skips unreadable rows" do
    result = Tempfile.create([ "logs", ".csv" ]) do |file|
      file.write(<<~CSV)
        start_time,end_time,intensity,medication,triggers,notes
        2024-03-01 08:00:00,2024-03-01 10:30:00,7,Sumatriptan,Lack of sleep,Morning attack
        2024-13-45 08:00:00,,7,,,Impossible date
        not a date,,7,,,Garbage
        2024-03-02 08:00:00,,15,,,Too intense
      CSV
      file.rewind

      HeadacheLog.import_csv(file: file, user: @user)
    end

    assert_equal :cluster_headache_tracker, result.format
    assert_equal 1, result.imported
    assert_equal 3, result.invalid
  end

  private
    def csv_fixture(name)
      Rack::Test::UploadedFile.new(file_fixture(name), "text/csv")
    end

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
