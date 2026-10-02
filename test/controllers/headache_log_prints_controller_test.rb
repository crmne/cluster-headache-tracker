require "test_helper"

class HeadacheLogPrintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test "the printed report includes the medication summary and each attack's doses" do
    get headache_log_print_url

    assert_response :success
    assert_select "#medication_insights tr", text: /Oxygen/
    assert_select "#headache_log_entries .medication-tag", text: /Sumatriptan · 6 mg/
  end

  test "filters the report by medication" do
    get headache_log_print_url(medication: "zolmi")

    assert_response :success
    assert_select "#headache_log_entries .medication-tag", text: /Zolmitriptan/
    assert_select "#headache_log_entries .medication-tag", text: /Sumatriptan/, count: 0
  end
end
