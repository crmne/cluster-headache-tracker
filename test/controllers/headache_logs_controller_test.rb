require "test_helper"

class HeadacheLogsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  setup do
    @user = users(:one)
    @headache_log = headache_logs(:one)
    sign_in @user
  end

  test "should get index" do
    get headache_logs_url
    assert_response :success
    assert_select "title", /Headache Logs/  # Changed from h1 to title
    assert_select ".navbar", /Headache Logs/  # Check navbar title instead
  end

  test "shows attack-free streaks on the dashboard" do
    sign_in users(:carmine)
    log_attack_for users(:carmine), "2026-06-01 02:00"
    log_attack_for users(:carmine), "2026-06-03 02:00"
    log_attack_for users(:carmine), "2026-09-28 02:00"

    travel_to Time.utc(2026, 10, 2, 12, 0) do
      get headache_logs_url
    end

    assert_select "#current_streak .stat-value", text: "4 days"
    assert_select "#longest_streak .stat-value", text: "116 days"
    assert_select "#attack_days .stat-value", text: "3"
    assert_select "#attack_days .stat-desc", text: "in 2 cycles"
  end

  test "shows an ongoing attack instead of a streak" do
    @headache_log.update!(end_time: nil)

    get headache_logs_url

    assert_select "#current_streak .stat-value", text: "Attack ongoing"
  end

  test "counts streak days in the time zone the browser reports" do
    sign_in users(:carmine)
    log_attack_for users(:carmine), "2026-10-02 01:00"

    travel_to Time.utc(2026, 10, 2, 20, 0) do
      get headache_logs_url
      assert_select "#current_streak .stat-value", text: "0 days"

      cookies[:time_zone] = "Pacific/Auckland"
      get headache_logs_url
      assert_select "#current_streak .stat-value", text: "1 day"

      cookies[:time_zone] = "Not/AZone"
      get headache_logs_url
      assert_select "#current_streak .stat-value", text: "0 days"
    end
  end

  test "should not find another user's headache log" do
    get edit_headache_log_url(headache_logs(:two))
    assert_response :not_found
  end

  test "edit keeps the end time of a finished headache" do
    get edit_headache_log_url(@headache_log)

    assert_select "input[name='headache_log[end_time]'][value=?]", @headache_log.end_time.strftime("%Y-%m-%dT%H:%M:%S")
  end

  test "should show ongoing headaches alert" do
    @headache_log.update(end_time: nil)
    get headache_logs_url
    assert_select ".alert", /Ongoing Headache/i
  end

  test "should generate share link" do
    assert_difference("ShareToken.count") do
      post share_link_url
    end
    assert_redirected_to headache_logs_url
    assert_equal "Share link generated successfully.", flash[:notice]
  end

  test "should expire share link" do
    ShareToken.destroy_all
    @user.share_tokens.create!
    assert_difference("ShareToken.count", -1) do
      delete share_link_url
    end
    assert_redirected_to headache_logs_url
    assert_equal "Share link has been expired.", flash[:notice]
  end

  test "should create a log with barometric pressure" do
    assert_difference("HeadacheLog.count") do
      post headache_logs_url, params: { headache_log: { start_time: "2024-03-01T08:00", intensity: 6, barometric_pressure: "1009.4" } }
    end

    assert_redirected_to headache_logs_url
    assert_equal BigDecimal("1009.4"), @user.headache_logs.recent_first.find_by!(start_time: Time.zone.parse("2024-03-01 08:00")).barometric_pressure
  end

  test "should create a log without barometric pressure" do
    assert_difference("HeadacheLog.count") do
      post headache_logs_url, params: { headache_log: { start_time: "2024-03-01T08:00", intensity: 6, barometric_pressure: "" } }
    end

    assert_nil @user.headache_logs.find_by!(start_time: Time.zone.parse("2024-03-01 08:00")).barometric_pressure
  end

  test "should reject implausible barometric pressure" do
    assert_no_difference("HeadacheLog.count") do
      post headache_logs_url, params: { headache_log: { start_time: "2024-03-01T08:00", intensity: 6, barometric_pressure: "29.92" } }
    end

    assert_response :unprocessable_entity
    assert_select ".alert-error", /Barometric pressure must be between 870 and 1085 hPa/
  end

  test "should update barometric pressure" do
    patch headache_log_url(@headache_log), params: { headache_log: { barometric_pressure: "998.7" } }

    assert_redirected_to headache_logs_url
    assert_equal BigDecimal("998.7"), @headache_log.reload.barometric_pressure
  end

  test "should show barometric pressure on the log and in the form" do
    get headache_log_url(@headache_log)
    assert_select "##{dom_id(@headache_log)}", /1008.5 hPa/

    get edit_headache_log_url(@headache_log)
    assert_select "input[name='headache_log[barometric_pressure]'][value='1008.5'][min='870'][max='1085']"
  end

  test "should show barometric pressure in the print report" do
    get headache_log_print_url
    assert_select "th", /Pressure/
    assert_select "td", /1008.5 hPa/
    assert_select "canvas#pressureChart"
  end

  test "should export logs to CSV" do
    get headache_log_export_url(format: :csv)
    assert_response :success
    assert_equal "text/csv", @response.content_type
    assert_match /start_time,end_time,intensity,medication,triggers,notes/, response.body
  end

  test "should import logs from CSV" do
    file = fixture_file_upload("test/fixtures/files/sample_logs.csv", "text/csv")
    assert_difference("HeadacheLog.count", 3) do
      post headache_log_import_url, params: { file: file }
    end
    assert_redirected_to headache_logs_url
    assert_equal "Detected a Cluster Headache Tracker CSV. Imported 3 headache logs.", flash[:notice]

    log = @user.headache_logs.find_by!(notes: "Morning attack")
    assert_equal Time.zone.parse("2024-03-01 08:00:00"), log.start_time
    assert_equal Time.zone.parse("2024-03-01 10:30:00"), log.end_time
    assert_equal 7, log.intensity
    assert_equal "sumatriptan", log.medication
    assert_equal "Lack of sleep", log.triggers
  end

  test "should import barometric pressure from CSV and skip implausible readings" do
    assert_difference("HeadacheLog.count", 2) do
      import_csv <<~CSV
        start_time,end_time,intensity,medication,triggers,notes,barometric_pressure
        2024-03-01 08:00:00,2024-03-01 09:00:00,7,Oxygen,,Low pressure,998.3
        2024-03-02 08:00:00,2024-03-02 09:00:00,7,Oxygen,,Inches of mercury,29.92
        2024-03-03 08:00:00,2024-03-03 09:00:00,7,Oxygen,,No reading,
      CSV
    end

    assert_equal BigDecimal("998.3"), @user.headache_logs.find_by!(notes: "Low pressure").barometric_pressure
    assert_nil @user.headache_logs.find_by!(notes: "No reading").barometric_pressure
  end

  test "should round-trip logs through export and import unchanged" do
    @user.headache_logs.destroy_all
    @user.headache_logs.create!(
      start_time: Time.zone.parse("2024-03-01 08:00:00"),
      end_time: Time.zone.parse("2024-03-01 10:30:00"),
      intensity: 7,
      medication: "Sumatriptan",
      triggers: "Lack of sleep",
      notes: "Morning attack"
    )
    @user.headache_logs.create!(
      start_time: Time.zone.parse("2024-03-02 23:00:00"),
      intensity: 9,
      medication: "Oxygen, Verapamil",
      triggers: "Alcohol",
      barometric_pressure: 1002.4
    )

    get headache_log_export_url(format: :csv)
    exported_csv = response.body

    @user.headache_logs.destroy_all
    assert_difference("HeadacheLog.count", 2) do
      import_csv exported_csv
    end

    get headache_log_export_url(format: :csv)
    assert_equal exported_csv, response.body
  end

  test "should filter logs by date range" do
    get headache_logs_url, params: {
      start_time: Date.yesterday,
      end_time: Date.tomorrow
    }
    assert_response :success
  end

  test "should filter logs by triggers" do
    get headache_logs_url, params: { triggers: "Sleeping" }
    assert_response :success
  end

  test "should filter logs by medication" do
    get headache_logs_url, params: { medication: "Sumatriptan" }
    assert_response :success
  end

  private
    def import_csv(contents)
      Tempfile.create([ "headache_logs", ".csv" ]) do |file|
        file.write(contents)
        file.rewind

        post headache_log_import_url, params: { file: Rack::Test::UploadedFile.new(file.path, "text/csv") }
      end
    end

    def log_attack_for(user, start_time)
      user.headache_logs.create!(start_time: Time.zone.parse(start_time), end_time: Time.zone.parse(start_time) + 1.hour, intensity: 7)
    end
end
