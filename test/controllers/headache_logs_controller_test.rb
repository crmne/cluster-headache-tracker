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

  test "new log offers recent attack medications before preventives in the picker" do
    get new_headache_log_url

    assert_response :success
    options = css_select("button.medication-option").map { |button| button.text.squish }
    assert_equal "Zolmitriptan", options.first
    assert options.index("Oxygen") < options.index("Lithium")
    assert_select "template#dose_template_medication_#{medications(:oxygen).id} input[name=?][value=?]",
      "headache_log[medication_doses_attributes][NEW_DOSE][amount]", "15"
  end

  test "someone without medications is offered the usual abortives" do
    sign_in users(:carmine)

    get new_headache_log_url

    assert_equal %w[ Oxygen Sumatriptan Zolmitriptan ], css_select("button.medication-option").map { |button| button.text.squish }
  end

  test "creates a log with doses picked in the form, including a new medication" do
    assert_difference -> { @user.medication_doses.count }, 2 do
      post headache_logs_url, params: { headache_log: { start_time: "2026-03-01T02:00", intensity: 8, medication_doses_attributes: {
        "1" => { medication_id: medications(:oxygen).id, taken_at: "2026-03-01T02:05", amount: "15", unit: "L/min", duration_minutes: "20" },
        "2" => { medication_name: "Lidocaine nasal spray", medication_kind: "abortive", taken_at: "2026-03-01T02:10" }
      } } }
    end

    assert_redirected_to headache_logs_url
    log = @user.headache_logs.find_by!(start_time: Time.zone.parse("2026-03-01 02:00"))
    assert_equal "oxygen 15 l/min 20 min, lidocaine nasal spray", log.medication
    assert @user.medications.named("Lidocaine nasal spray").abortive?
  end

  test "can't attach another user's medication to a log" do
    assert_no_difference -> { HeadacheLog.count } do
      post headache_logs_url, params: { headache_log: { start_time: "2026-03-01T02:00", intensity: 8, medication_doses_attributes: {
        "1" => { medication_id: medications(:sumatriptan_two).id, taken_at: "2026-03-01T02:05" }
      } } }
    end

    assert_response :unprocessable_entity
  end

  test "edit shows existing doses with a rating" do
    get edit_headache_log_url(headache_logs(:three))

    assert_select "[data-medication-picker-target=doses] [data-medication-picker-target=dose]", 2
    assert_select "input[type=radio][name=?][value=helped][checked]", "headache_log[medication_doses_attributes][1][effectiveness]"
  end

  test "index asks how the medication worked after an attack ended" do
    @headache_log.update!(start_time: 2.hours.ago, end_time: 30.minutes.ago)

    get headache_logs_url

    assert_select "#dose_review_headache_log_#{@headache_log.id}" do
      assert_select "button", text: /Helped/
      assert_select "button", text: /No effect/
      assert_select "button", text: /Made worse/
    end
  end

  test "index nudges preventives that are due" do
    get headache_logs_url

    assert_select "#due_medications", text: /Lithium/
    assert_select "#due_medications", text: /0 of 2 today/
  end

  test "cards show doses as tags with their rating" do
    get headache_logs_url

    assert_select "#headache_log_#{headache_logs(:three).id} .medication-tag", text: "Oxygen · 15 L/min · 15 min"
    assert_select "#headache_log_#{headache_logs(:three).id} [aria-label=Helped]"
  end
end
