require "application_system_test_case"

class ChartsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user

    # Create some headache logs with trigger data
    3.times do |i|
      HeadacheLog.create!(
        user: @user,
        start_time: Time.current - i.days,
        end_time: Time.current - i.days + 2.hours,
        intensity: rand(1..10),
        triggers: "Stress, Lack of Sleep",
        medication: "Sumatriptan"
      )
    end
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
