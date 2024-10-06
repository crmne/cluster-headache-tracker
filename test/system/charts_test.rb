require "application_system_test_case"

class ChartsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "visiting the charts page" do
    visit charts_url
    assert_selector "h1", text: "Headache Data Visualization"
    assert_selector "h2", text: "Headache Intensity Over Time"
    assert_selector "h2", text: "Number of Attacks per Day"
    assert_selector "h2", text: "Top 5 Triggers"
    assert_selector "h2", text: "Top 5 Medications"
    assert_selector "h2", text: "Headache Frequency and Intensity by Time of Day"
  end

  test "charts are rendered" do
    visit charts_url
    assert_selector "canvas#intensityChart"
    assert_selector "canvas#attacksPerDayChart"
    assert_selector "canvas#triggerChart"
    assert_selector "canvas#medicationChart"
    assert_selector "canvas#hourlyChart"
  end
end
