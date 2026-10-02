require "application_system_test_case"

class ChartsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "viewing charts" do
    visit charts_url
    assert_selector "canvas#intensityChart"
    assert_selector "canvas#triggerChart"
    assert_selector "canvas#medicationChart"
    assert_selector "canvas#hourlyChart"
    assert_selector "canvas#attacksPerDayChart"
    assert_selector "canvas#pressureChart"
    assert_text "Log the pressure for attacks less than 24 hours apart"
  end

  test "viewing pressure change between attacks" do
    headache_logs(:three).update!(start_time: headache_logs(:one).start_time - 6.hours)

    visit charts_url
    assert_selector "canvas#pressureChangeChart"
  end
end
