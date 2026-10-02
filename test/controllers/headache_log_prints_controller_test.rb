require "test_helper"

class HeadacheLogPrintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test "print report includes streaks and cycles" do
    get headache_log_print_url

    assert_response :success
    assert_select "#attack_streaks"
    assert_select "#cycles #attack_calendar"
    assert_select "#cycles_table tbody tr", count: 1
  end
end
