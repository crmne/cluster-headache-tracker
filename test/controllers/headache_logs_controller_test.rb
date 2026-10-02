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

  test "quick log shows the one-tap intensity pad" do
    get new_headache_log_url(quick: 1)

    assert_response :success
    assert_select ".navbar", /Quick log/
    assert_select "form#start_attack[action=?] button[name=intensity]", current_attack_path, count: 10
  end

  test "quick log shows the ongoing attack instead of starting another" do
    @headache_log.update!(end_time: nil)

    get new_headache_log_url(quick: 1)

    assert_response :success
    assert_select "#end_attack"
    assert_select "#start_attack", count: 0
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

  test "should create a log with photos" do
    assert_difference -> { ActiveStorage::Attachment.count }, 2 do
      post headache_logs_url, params: { headache_log: {
        start_time: Time.current, intensity: 6,
        photos: [ fixture_file_upload("photo.jpg", "image/jpeg"), fixture_file_upload("photo.heic", "image/heic") ]
      } }
    end

    assert_redirected_to headache_logs_url
    assert_equal 2, @user.headache_logs.order(:created_at).last.photos.count
  end

  test "should keep stored photos when adding more" do
    @headache_log.photos.attach(io: file_fixture("photo.jpg").open, filename: "kept.jpg")

    patch headache_log_url(@headache_log), params: { headache_log: {
      photos: [ @headache_log.photos.first.signed_id, fixture_file_upload("photo.heic", "image/heic") ]
    } }

    assert_redirected_to headache_logs_url
    assert_equal %w[ kept.jpg photo.heic ], @headache_log.photos.reload.map { |photo| photo.filename.to_s }.sort
  end

  test "should reject a sixth photo" do
    5.times { @headache_log.photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg") }

    patch headache_log_url(@headache_log), params: { headache_log: {
      photos: @headache_log.photos.map(&:signed_id) + [ fixture_file_upload("photo.jpg", "image/jpeg") ]
    } }

    assert_response :unprocessable_entity
    assert_select ".alert-error", /Photos can't be more than 5 per attack/
    assert_equal 5, @headache_log.photos.reload.count
  end

  test "should show the log's photos" do
    @headache_log.photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")

    get headache_log_url(@headache_log)

    assert_select "img[src=?]", headache_log_photo_variant_path(@headache_log, @headache_log.photos.first, :thumb)
  end

  test "should include photos in the print report" do
    @headache_log.photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")

    get headache_log_print_url

    assert_response :success
    assert_select "img[src=?]", headache_log_photo_variant_path(@headache_log, @headache_log.photos.first, :large)
  end

  test "Turbo form submissions land on the logs page instead of streaming into the form" do
    turbo_headers = { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }

    patch headache_log_url(@headache_log), params: { headache_log: { intensity: 6 } }, headers: turbo_headers
    follow_redirect! headers: turbo_headers

    assert_equal "text/html", response.media_type
    assert_select "title", /Headache Logs/
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
