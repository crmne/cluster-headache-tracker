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

  test "index and form in German with a 24-hour clock" do
    @user.update!(locale: "de", time_format: "24h")
    @user.headache_logs.create!(start_time: Time.zone.parse("2026-03-14 19:05"), end_time: Time.zone.parse("2026-03-14 19:50"), intensity: 8)

    get headache_logs_url
    assert_response :success
    assert_select "html[lang=de]"
    assert_select ".navbar", /Kopfschmerz-Tagebuch/
    assert_select "##{dom_id(@user.headache_logs.find_by!(intensity: 8))}", /14\. Mär 2026 · 19:05/
    assert_select "##{dom_id(@user.headache_logs.find_by!(intensity: 8))}", text: /PM/, count: 0
    assert_select "body[data-hour-cycle=h23]"

    get new_headache_log_url
    assert_response :success
    assert_select "h3", /Beginn/
    assert_select "h3", /Schmerzintensität/
    assert_select "#common-medications option[value=Sauerstoff]"
    assert_select "input[type=submit][value='Eintrag erstellen']"
  end

  test "times honor a 12-hour preference regardless of language" do
    @user.update!(locale: "de", time_format: "12h")
    log = @user.headache_logs.create!(start_time: Time.zone.parse("2026-03-14 19:05"), intensity: 8)

    get headache_logs_url
    assert_response :success
    assert_select "##{dom_id(log)}", /14\. Mär 2026 · 7:05 PM/
    assert_select ".alert", /Laufende Attacke/
    assert_select "body[data-hour-cycle=h12]"
  end

  test "English defaults to a 12-hour clock" do
    log = @user.headache_logs.create!(start_time: Time.zone.parse("2026-03-14 19:05"), end_time: Time.zone.parse("2026-03-14 19:50"), intensity: 8)

    get headache_logs_url
    assert_select "##{dom_id(log)}", /Mar 14, 2026 · 7:05 PM/
  end

  test "flashes and validation errors follow the user's language" do
    @user.update!(locale: "it")

    post headache_logs_url, params: { headache_log: { start_time: "", intensity: 5 } }
    assert_response :unprocessable_entity
    assert_select ".alert-error li", /Ora di inizio/

    post headache_logs_url, params: { headache_log: { start_time: "2026-03-14T19:05", intensity: 5 } }
    assert_equal "Registrazione salvata.", flash[:notice]
  end

  test "import notice pluralizes the count" do
    @user.update!(locale: "es")
    file = fixture_file_upload("test/fixtures/files/sample_logs.csv", "text/csv")

    post headache_log_import_url, params: { file: file }
    assert_equal "Se importaron 3 registros.", flash[:notice]
  end
end
