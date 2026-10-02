require "test_helper"

class MedicationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "index lists active medications as one-tap buttons and stopped ones apart" do
    medications(:zolmitriptan).update!(archived: true)

    get medications_url

    assert_response :success
    assert_select "#medications .medication-tag", text: "Oxygen"
    assert_select "#medications button[aria-label=?]", "Log a dose of Lithium taken now"
    assert_select "#medications .medication-tag", text: "Zolmitriptan", count: 0
    assert_select "details summary", text: "1 stopped medication"
  end

  test "show summarises the medication and lists its doses" do
    get medication_url(medications(:oxygen))

    assert_response :success
    assert_select "dd", text: /100%/
    assert_select "li", text: /15 L\/min · 15 min/
  end

  test "creates a medication" do
    assert_difference -> { @user.medications.count } do
      post medications_url, params: { medication: { name: "Verapamil", kind: "preventive", default_dose: "240", unit: "mg",
        frequency: "three_times_daily", schedule_note: "with meals" } }
    end

    assert_redirected_to medications_url
    verapamil = @user.medications.named("verapamil")
    assert_equal [ "preventive", 240, "mg", "three_times_daily", "with meals" ],
      [ verapamil.kind, verapamil.default_dose, verapamil.unit, verapamil.frequency, verapamil.schedule_note ]
  end

  test "rejects a duplicate name" do
    assert_no_difference -> { Medication.count } do
      post medications_url, params: { medication: { name: "oxygen", kind: "oxygen" } }
    end

    assert_response :unprocessable_entity
  end

  test "updates and archives a medication" do
    patch medication_url(medications(:sumatriptan)), params: { medication: { default_dose: "12", color: "#ef4444", archived: "1" } }

    assert_redirected_to medication_url(medications(:sumatriptan))
    sumatriptan = medications(:sumatriptan).reload
    assert_equal [ 12, "#ef4444", true ], [ sumatriptan.default_dose, sumatriptan.color, sumatriptan.archived? ]
  end

  test "destroys a medication with its doses" do
    assert_difference -> { MedicationDose.count }, -1 do
      delete medication_url(medications(:oxygen))
    end

    assert_redirected_to medications_url
  end

  test "merges a duplicate into another medication" do
    typo = @user.medications.create!(name: "Sumatriptin")
    @user.medication_doses.create!(medication: typo, taken_at: 5.days.ago)

    assert_difference -> { medications(:sumatriptan).doses.count } do
      post medication_merge_url(typo), params: { target_id: medications(:sumatriptan).id }
    end

    assert_redirected_to medication_url(medications(:sumatriptan))
    assert_not Medication.exists?(typo.id)
  end

  test "can't merge into another user's medication" do
    post medication_merge_url(medications(:sumatriptan)), params: { target_id: medications(:sumatriptan_two).id }

    assert_response :not_found
    assert Medication.exists?(medications(:sumatriptan).id)
  end

  test "can't see another user's medications" do
    get medication_url(medications(:sumatriptan_two))

    assert_response :not_found
  end

  test "can't change another user's medications" do
    patch medication_url(medications(:sumatriptan_two)), params: { medication: { name: "Mine now" } }

    assert_response :not_found
    assert_equal "Sumatriptan", medications(:sumatriptan_two).reload.name
  end

  test "requires authentication" do
    sign_out @user

    get medications_url
    assert_redirected_to new_user_session_url
  end

  test "renders in German" do
    get medications_url(locale: "de")

    assert_response :success
    assert_select "button[aria-label=?]", "Einnahme von Lithium jetzt erfassen"
  end
end
