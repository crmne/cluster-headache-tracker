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

    # Use JavaScript to set date fields directly
    yesterday = Date.yesterday.to_s
    tomorrow = Date.tomorrow.to_s

    page.execute_script("document.querySelectorAll('fieldset input[type=\"date\"]')[0].value = '#{yesterday}'")
    page.execute_script("document.querySelectorAll('fieldset input[type=\"date\"]')[1].value = '#{tomorrow}'")

    # Set trigger input
    page.execute_script("document.querySelector('input[name=\"triggers\"]').value = 'Sleeping'")

    click_on "Apply Filters"

    assert_selector "canvas#intensityChart"
  end

  test "charts show no data message when filtered with no results" do
    visit charts_url
    open_accordion "filters"

    # Use JavaScript to set date fields to a period with no data
    one_year_ago = 1.year.ago.to_date.to_s
    eleven_months_ago = 11.months.ago.to_date.to_s

    page.execute_script("document.querySelectorAll('fieldset input[type=\"date\"]')[0].value = '#{one_year_ago}'")
    page.execute_script("document.querySelectorAll('fieldset input[type=\"date\"]')[1].value = '#{eleven_months_ago}'")

    click_on "Apply Filters"

    assert_text "No headache data available"
  end
end
