require "test_helper"

class HeadacheLogsControllerTest < ActionDispatch::IntegrationTest
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
    assert_match /Successfully imported/, flash[:notice]

    log = @user.headache_logs.find_by!(notes: "Morning attack")
    assert_equal Time.zone.parse("2024-03-01 08:00:00"), log.start_time
    assert_equal Time.zone.parse("2024-03-01 10:30:00"), log.end_time
    assert_equal 7, log.intensity
    assert_equal "sumatriptan", log.medication
    assert_equal "Lack of sleep", log.triggers
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
      triggers: "Alcohol"
    )

    get headache_log_export_url(format: :csv)
    exported_csv = response.body

    @user.headache_logs.destroy_all
    Tempfile.create([ "exported_logs", ".csv" ]) do |file|
      file.write(exported_csv)
      file.rewind

      assert_difference("HeadacheLog.count", 2) do
        post headache_log_import_url, params: { file: Rack::Test::UploadedFile.new(file.path, "text/csv") }
      end
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
    def log_attack_for(user, start_time)
      user.headache_logs.create!(start_time: Time.zone.parse(start_time), end_time: Time.zone.parse(start_time) + 1.hour, intensity: 7)
    end
end
