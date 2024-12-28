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
    log.update!(end_time: nil)

    # Visit the headache logs page
    visit headache_logs_url
    assert_text "Ongoing"

    # Click through to edit the log
    click_on "Update Log"
    assert_current_path edit_headache_log_path(log)

    # Fill in all required fields, not just end_time
    fill_in "Start Time", with: log.start_time.strftime("%Y-%m-%dT%H:%M")
    fill_in "End Time", with: Time.current.strftime("%Y-%m-%dT%H:%M")
    fill_in "Intensity", with: log.intensity

    # Debug output
    puts "Form values before submission:"
    puts "Start time: #{find_field('Start Time').value}"
    puts "End time: #{find_field('End Time').value}"
    puts "Intensity: #{find_field('Intensity').value}"

    # Submit form and debug any validation errors
    click_button "Update Headache log"

    if page.has_css?(".alert")
      puts "Validation errors found:"
      puts page.find(".alert").text
    end

    assert_current_path headache_log_path(log)
    assert_text "Headache log was successfully updated"
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
