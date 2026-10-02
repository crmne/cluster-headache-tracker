require "test_helper"

class TimelinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "shows attacks with their doses and standalone doses" do
    get timeline_url

    assert_response :success
    assert_select "#timeline_headache_log_#{headache_logs(:three).id}" do
      assert_select ".medication-tag", text: /Oxygen · 15 L\/min · 15 min/
      assert_select "[role=img][aria-label=?]", "2 doses during this attack"
    end
    assert_select "#timeline_medication_dose_#{medication_doses(:lithium_yesterday).id} .medication-tag", text: /Lithium/
    assert_select "#timeline_headache_log_#{headache_logs(:two).id}", count: 0
  end

  test "pages back" do
    get timeline_url(before: headache_logs(:one).start_time.iso8601(6))

    assert_response :success
    assert_select "#timeline_headache_log_#{headache_logs(:one).id}", count: 0
    assert_select "#timeline_headache_log_#{headache_logs(:three).id}"
  end

  test "is empty for someone who hasn't logged anything" do
    sign_in users(:carmine)

    get timeline_url

    assert_select "p", text: /Nothing logged yet/
  end
end
