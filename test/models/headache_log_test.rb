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

    assert_equal 2, bucket[:start_hour]
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

  test "barometric pressure is optional" do
    @headache_log.barometric_pressure = nil
    assert @headache_log.valid?

    @headache_log.barometric_pressure = ""
    assert @headache_log.valid?
    assert_nil @headache_log.barometric_pressure
  end

  test "barometric pressure must be within the plausible range" do
    @headache_log.barometric_pressure = 869.9
    assert_not @headache_log.valid?
    assert_includes @headache_log.errors[:barometric_pressure], "must be between 870 and 1085 hPa"

    @headache_log.barometric_pressure = 1085.1
    assert_not @headache_log.valid?

    @headache_log.barometric_pressure = 870
    assert @headache_log.valid?

    @headache_log.barometric_pressure = 1085
    assert @headache_log.valid?
  end

  test "barometric pressure must be a number" do
    @headache_log.barometric_pressure = "high"
    assert_not @headache_log.valid?
    assert_includes @headache_log.errors[:barometric_pressure], "must be a number in hPa"
  end

  test "barometric pressure is stored to one decimal place" do
    @headache_log.update!(barometric_pressure: "1013.25")
    assert_equal BigDecimal("1013.3"), @headache_log.reload.barometric_pressure
  end

  test "database rejects implausible barometric pressure" do
    @headache_log.save!

    assert_raises ActiveRecord::StatementInvalid do
      @headache_log.update_column(:barometric_pressure, 500)
    end
  end

  test "chart_data buckets attacks by barometric pressure and fills empty bands" do
    logs = [
      chart_log(intensity: 6, barometric_pressure: 1001.4),
      chart_log(intensity: 8, barometric_pressure: 1004.9),
      chart_log(intensity: 9, barometric_pressure: 1012.0),
      chart_log(intensity: 3)
    ]

    pressure_data = HeadacheLog.chart_data_for(logs)[:pressure_data]

    assert_equal [ "1000–1005", "1005–1010", "1010–1015" ], pressure_data.map { |band| band[:label] }
    assert_equal [ 2, 0, 1 ], pressure_data.map { |band| band[:frequency] }
    assert_equal [ 7.0, 0, 9.0 ], pressure_data.map { |band| band[:avg_intensity] }
  end

  test "chart_data has no pressure data without readings" do
    chart_data = HeadacheLog.chart_data_for([ chart_log, chart_log ])

    assert_empty chart_data[:pressure_data]
    assert_empty chart_data[:pressure_change_data]
  end

  test "chart_data tracks pressure change between readings within a day" do
    logs = [
      chart_log(start_time: "2024-03-02 20:00", intensity: 9, barometric_pressure: 1004.5),
      chart_log(start_time: "2024-03-01 08:00", barometric_pressure: 1015.0),
      chart_log(start_time: "2024-03-02 02:00", barometric_pressure: 1010.0),
      chart_log(start_time: "2024-03-02 10:00"),
      chart_log(start_time: "2024-03-05 02:00", barometric_pressure: 1020.0)
    ]

    pressure_change_data = HeadacheLog.chart_data_for(logs)[:pressure_change_data]

    assert_equal 2, pressure_change_data.size
    assert_equal({ x: Time.zone.parse("2024-03-02 02:00").iso8601, y: -5.0, pressure: 1010.0, hours: 18.0, intensity: 5 }, pressure_change_data.first)
    assert_equal({ x: Time.zone.parse("2024-03-02 20:00").iso8601, y: -5.5, pressure: 1004.5, hours: 18.0, intensity: 9 }, pressure_change_data.second)
  end

  test "to_csv exports barometric pressure" do
    @headache_log.update!(start_time: Time.zone.parse("2024-03-01 08:00"), barometric_pressure: 1013.2)

    csv = CSV.parse(@user.headache_logs.where(id: @headache_log).to_csv, headers: true)

    assert_equal "1013.2", csv.first["barometric_pressure"]
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

  test "should filter by medication through doses, ignoring case" do
    HeadacheLog.where(id: headache_logs(:three)).update_all(medication: nil)

    filtered_logs = @user.headache_logs.filtered_by({ medication: "oxy" })

    assert_equal [ headache_logs(:three) ], filtered_logs.to_a
  end

  test "should filter by medication text of logs from before doses" do
    legacy = @user.headache_logs.create!(start_time: 5.days.ago, intensity: 6, medication: "Verapamil")

    assert_includes @user.headache_logs.filtered_by({ medication: "verapamil" }), legacy
  end

  test "chart_data counts medications from doses with their colors" do
    chart_data = @user.headache_logs.chart_data

    assert_equal({ "Zolmitriptan" => 1, "Sumatriptan" => 1, "Oxygen" => 1 }, chart_data[:medication_data])
    assert_equal "#0ea5e9", chart_data[:medication_colors]["Oxygen"]
  end

  test "saves doses picked in the form and mirrors them into the medication text" do
    log = @user.headache_logs.create!(start_time: 1.hour.ago, intensity: 9, medication_doses_attributes: {
      "0" => { medication_id: medications(:oxygen).id, taken_at: 50.minutes.ago, amount: "12", duration_minutes: "15" },
      "1" => { medication_name: "Lidocaine", medication_kind: "abortive", taken_at: 45.minutes.ago },
      "2" => { medication_id: "", medication_name: "" }
    })

    assert_equal 2, log.medication_doses.count
    assert_equal "oxygen 12 l/min 15 min, lidocaine", log.medication
    assert_equal @user, log.medication_doses.first.user
    assert @user.medications.named("lidocaine").abortive?
  end

  test "removing a dose in the form updates the medication text" do
    log = headache_logs(:three)
    oxygen = medication_doses(:oxygen_for_three)

    log.update!(medication_doses_attributes: { "0" => { id: oxygen.id, _destroy: "1" } })

    assert_not MedicationDose.exists?(oxygen.id)
    assert_equal "sumatriptan 6 mg", log.reload.medication
  end

  test "saving a log without touching its doses keeps its text" do
    log = @user.headache_logs.create!(start_time: 5.days.ago, intensity: 6, medication: "Oxygen 15 min")

    log.update!(intensity: 7)

    assert_equal "oxygen 15 min", log.reload.medication
    assert_empty log.medication_doses
  end

  test "adding a dose to a log from before doses keeps what its text recorded" do
    log = @user.headache_logs.create!(start_time: 5.days.ago, intensity: 6, medication: "Oxygen 15 min")

    log.update!(medication_doses_attributes: { "0" => { medication_id: medications(:sumatriptan).id, taken_at: 5.days.ago } })

    assert_equal [ "Oxygen", "Sumatriptan" ], log.medication_doses.reload.map { |dose| dose.medication.name }
    assert_equal "oxygen 15 min, sumatriptan", log.reload.medication
  end

  test "deleting a log deletes its doses" do
    assert_difference -> { MedicationDose.count }, -2 do
      headache_logs(:three).destroy!
    end
  end

  test "awaiting dose review: recently ended attacks with unrated attack doses" do
    log = headache_logs(:one)
    log.update!(start_time: 2.hours.ago, end_time: 1.hour.ago)

    assert_equal [ log ], @user.headache_logs.awaiting_dose_review.to_a
    assert_equal [ medication_doses(:zolmitriptan_for_one) ], log.doses_awaiting_review

    medication_doses(:zolmitriptan_for_one).update!(effectiveness: "helped")
    assert_empty @user.headache_logs.awaiting_dose_review
  end

  test "importing CSV turns its medication text into doses" do
    @user.headache_logs.destroy_all

    HeadacheLog.import_csv(file: File.open(file_fixture("sample_logs.csv")), user: @user)

    log = @user.headache_logs.find_by!(notes: "Afternoon attack")
    assert_equal %w[ Sumatriptan Oxygen ], log.medication_doses.map { |dose| dose.medication.name }
    assert_equal [ log.start_time ] * 2, log.medication_doses.map(&:taken_at)
    assert_equal "sumatriptan, oxygen", log.medication
  end

  private
    def csv_fixture(name)
      Rack::Test::UploadedFile.new(file_fixture(name), "text/csv")
    end

    def chart_log(start_time: "2024-03-01 12:00", end_time: nil, intensity: 5, medication: nil, barometric_pressure: nil)
      HeadacheLog.new(
        user: @user,
        start_time: Time.zone.parse(start_time),
        end_time: end_time && Time.zone.parse(end_time),
        intensity: intensity,
        medication: medication,
        barometric_pressure: barometric_pressure
      )
    end
end
