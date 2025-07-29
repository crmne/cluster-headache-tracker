require "application_system_test_case"

class ChartsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

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
  end
end
