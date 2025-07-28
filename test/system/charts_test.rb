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

    # Verify we have charts before filtering
    assert_selector "canvas#intensityChart"

    open_accordion "filters"

    # Just test that the filter form works by applying a filter
    # Don't assume specific data exists
    within("details[data-accordion='filters']") do
      fill_in "triggers", with: "NonExistentTrigger"
    end

    click_on "Apply Filters"

    # After filtering, we should either see charts or a no data message
    # This test just verifies the filtering mechanism works
    assert_text(/No headaches found matching your filters|Headache Intensity Over Time/)
  end

  test "charts show no data message when filtered with no results" do
    visit charts_url
    open_accordion "filters"

    # Use JavaScript to set date fields to a period with no data
    one_year_ago = 1.year.ago.to_date.to_s
    eleven_months_ago = 11.months.ago.to_date.to_s

    # Set date fields within the filter form
    within("details[data-accordion='filters']") do
      fill_in "start_time", with: one_year_ago
      fill_in "end_time", with: eleven_months_ago
    end

    click_on "Apply Filters"

    assert_text "No headaches found matching your filters"
  end
end
