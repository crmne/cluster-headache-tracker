require "application_system_test_case"

class HeadacheLogsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "visiting the index" do
    visit headache_logs_url
    assert_selector "div.navbar-center", text: "Headache Logs"
    assert_selector ".stats", count: 1
    assert_selector ".card", minimum: 1
  end

  test "creating a new headache log" do
    visit headache_logs_url
    click_on "New"

    fill_in "Start Time", with: Time.current.strftime("%Y-%m-%dT%H:%M")
    fill_in "Intensity", with: 7
    fill_in "Medication", with: "Sumatriptan + Oxygen"
    fill_in "Triggers", with: "Lack of sleep, Stress"
    fill_in "Notes", with: "Severe headache on the right side"

    click_on "Create Headache log"

    assert_text "Headache log was successfully created"
    assert_text "Sumatriptan + Oxygen"
    assert_text "Lack of sleep"
  end

  test "updating a headache log" do
    visit headache_log_url(headache_logs(:one))
    click_on "Edit"

    fill_in "Intensity", with: 8
    fill_in "Notes", with: "Updated notes"
    click_on "Update Headache log"

    assert_text "Headache log was successfully updated"
    assert_text "Updated notes"
  end

  test "marking ongoing headache as complete" do
    # Create an ongoing headache log
    log = headache_logs(:one)
    end_time = log.end_time
    log.update(end_time: nil)

    # Visit the headache logs page
    visit headache_logs_url

    # Verify we see the "Ongoing" status
    assert_text "Ongoing"

    # Click the "Update Log" button and wait for the page to load
    click_on "Update Log"
    assert_current_path edit_headache_log_path(log)

    # Fill in the end time with the current time
    fill_in "End Time", with: end_time

    # Submit the form and wait for the update
    click_button "Update Headache log"

    # Verify the success message and that "Ongoing" is no longer present
    assert_text "Headache log was successfully updated"
    assert_no_text "Ongoing Headache"
  end

  test "filtering headache logs" do
    visit headache_logs_url
    open_accordion "filters"

    fill_in "Start Date", with: Date.yesterday
    fill_in "End Date", with: Date.tomorrow
    fill_in "Triggers", with: "Sleeping"

    click_on "Apply Filters"

    assert_text "Sleeping"
  end

  test "generating and copying share link" do
    visit headache_logs_url
    open_accordion "share"
    click_on "Generate New Link"

    assert_text "Share link generated successfully"

    click_on "Copy"
    assert_text "Copied!"
  end

  test "importing CSV file" do
    visit settings_url
    click_on "Import CSV"

    attach_file "file", "test/fixtures/files/sample_logs.csv"
    click_on "Import"

    assert_text "Successfully imported"
  end
end
