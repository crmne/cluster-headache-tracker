require "test_helper"

class MedicationDosesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "new offers every active medication as a one-tap button" do
    get new_medication_dose_url

    assert_response :success
    assert_select "form[action=?] button", medication_doses_path, minimum: 5
    assert_select "select#medication_dose_medication_id"
  end

  test "a one-tap dose uses the device time and the usual dose" do
    assert_difference -> { @user.medication_doses.count } do
      post medication_doses_url, params: { medication_dose: { medication_id: medications(:lithium).id, taken_at: "2026-03-01T08:15", amount: "300" } },
        headers: { "HTTP_REFERER" => medications_url }
    end

    assert_redirected_to medications_url
    dose = @user.medication_doses.order(:created_at).last
    assert_equal [ Time.zone.parse("2026-03-01 08:15"), 300, "mg" ], [ dose.taken_at, dose.amount, dose.unit ]
  end

  test "creates a dose for a medication typed by name" do
    assert_difference -> { @user.medications.count } do
      post medication_doses_url, params: { medication_dose: { medication_name: "Melatonin", taken_at: "2026-03-01T22:00" } }
    end

    assert_redirected_to timeline_url
    assert @user.medications.named("melatonin").preventive?
  end

  test "can't log a dose of another user's medication" do
    assert_no_difference -> { MedicationDose.count } do
      post medication_doses_url, params: { medication_dose: { medication_id: medications(:sumatriptan_two).id } }
    end

    assert_response :unprocessable_entity
  end

  test "rating a dose from the review prompt asks for the time to relief" do
    dose = medication_doses(:zolmitriptan_for_one)

    patch medication_dose_url(dose), params: { medication_dose: { effectiveness: "helped" } }, as: :turbo_stream

    assert_response :success
    assert dose.reload.helped?
    assert_turbo_stream action: :replace, target: "review_medication_dose_#{dose.id}" do
      assert_select "button", text: "15 min"
    end
    assert_turbo_stream action: :replace, target: "headache_log_#{dose.headache_log_id}"
  end

  test "answering the time to relief completes the review" do
    dose = medication_doses(:zolmitriptan_for_one)
    dose.update!(effectiveness: "helped")

    patch medication_dose_url(dose), params: { medication_dose: { minutes_to_relief: "15" } }, as: :turbo_stream

    assert_equal 15, dose.reload.minutes_to_relief
    assert_turbo_stream action: :replace, target: "review_medication_dose_#{dose.id}" do
      assert_select "p", text: /Thanks, saved/
    end
  end

  test "edits and deletes a dose" do
    dose = medication_doses(:lithium_yesterday)

    get edit_medication_dose_url(dose)
    assert_response :success

    patch medication_dose_url(dose), params: { medication_dose: { amount: "450" } }
    assert_redirected_to timeline_url
    assert_equal 450, dose.reload.amount

    assert_difference -> { MedicationDose.count }, -1 do
      delete medication_dose_url(dose)
    end
    assert_redirected_to timeline_url
  end

  test "can't touch another user's dose" do
    patch medication_dose_url(medication_doses(:sumatriptan_for_two)), params: { medication_dose: { effectiveness: "helped" } }

    assert_response :not_found
    assert_nil medication_doses(:sumatriptan_for_two).reload.effectiveness
  end

  test "exports doses to CSV" do
    get medication_dose_export_url(format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match(/\Ataken_at,medication,kind,amount,unit,duration_minutes,effectiveness,minutes_to_relief,attack_start_time/, response.body)
    assert_equal @user.medication_doses.count + 1, response.body.lines.size
  end

  test "imports a dose CSV through the shared import" do
    csv = @user.medication_doses.to_csv
    @user.medication_doses.where(headache_log_id: nil).delete_all

    Tempfile.create([ "doses", ".csv" ]) do |file|
      file.write(csv)
      file.rewind

      assert_difference -> { @user.medication_doses.count }, 1 do
        post headache_log_import_url, params: { file: Rack::Test::UploadedFile.new(file.path, "text/csv") }
      end
    end

    assert_redirected_to headache_logs_url
    assert_equal "Successfully imported 4 medication doses.", flash[:notice]
  end
end
