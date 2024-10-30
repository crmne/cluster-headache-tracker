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

  test "filtering chart data" do
    visit charts_url
    open_accordion "filters"

    fill_in "Start Date", with: Date.yesterday
    fill_in "End Date", with: Date.tomorrow
    fill_in "Triggers", with: "Sleeping"

    click_on "Apply Filters"

    assert_selector "canvas#intensityChart"
  end

  test "charts show no data message when filtered with no results" do
    visit charts_url
    open_accordion "filters"

    fill_in "Start Date", with: 1.year.ago
    fill_in "End Date", with: 11.months.ago

    click_on "Apply Filters"

    assert_text "No headache data available"
  end
end
