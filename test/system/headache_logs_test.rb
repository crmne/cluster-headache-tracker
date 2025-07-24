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

    # Add a small wait to ensure page is fully loaded
    sleep(0.5)

    # Use all().first to handle multiple datetime fields - this gets the first one (start time)
    datetime_input = all("input[type='datetime-local']").first
    if datetime_input
      datetime_input.set(Time.current.strftime("%Y-%m-%dT%H:%M"))
    else
      # Fallback: try finding by name attribute
      fill_in "headache_log[start_time]", with: Time.current.strftime("%Y-%m-%dT%H:%M")
    end

    # Intensity - using execute_script with a robust selector
    page.execute_script("document.querySelector('.range').value = 7")
    page.execute_script("document.querySelector('.range').dispatchEvent(new Event('input'))")

    # These should be more straightforward
    fill_in "headache_log[medication]", with: "Sumatriptan + Oxygen"
    fill_in "headache_log[triggers]", with: "Lack of sleep, Stress"
    fill_in "headache_log[notes]", with: "Severe headache on the right side"

    click_on "Create Headache log"

    assert_text "Headache log was successfully created"
    assert_text "Sumatriptan + Oxygen"
    assert_text "Lack of sleep"
  end

  test "updating a headache log" do
    visit headache_log_url(headache_logs(:one))
    click_on "Edit"

    # Add a small wait to ensure page is fully loaded
    sleep(0.5)

    # Debug the form structure if needed
    # puts page.html

    # Use a more general selector for the range input based on its CSS class
    page.execute_script("document.querySelector('.range').value = 8")
    page.execute_script("document.querySelector('.range').dispatchEvent(new Event('input'))")

    # Use a more reliable way to find the notes textarea
    fill_in "headache_log[notes]", with: "Updated notes"

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

    # Fill in the end time using JavaScript
    page.execute_script("document.querySelector('input[type=\"datetime-local\"][name=\"headache_log[end_time]\"]').value = '#{end_time.strftime("%Y-%m-%dT%H:%M")}'")

    # Submit the form and wait for the update
    click_button "Update Headache log"

    # Verify the success message and that "Ongoing" is no longer present
    assert_text "Headache log was successfully updated"
    assert_no_text "Ongoing Headache"
  end

  test "filtering headache logs" do
    visit headache_logs_url
    open_accordion "filters"

    # Use JavaScript to set date fields directly
    yesterday = Date.yesterday.to_s
    tomorrow = Date.tomorrow.to_s

    # We'll use nth-child to target specific elements
    page.execute_script("document.querySelectorAll('fieldset input[type=\"date\"]')[0].value = '#{yesterday}'")
    page.execute_script("document.querySelectorAll('fieldset input[type=\"date\"]')[1].value = '#{tomorrow}'")

    # Set trigger input
    page.execute_script("document.querySelector('input[name=\"triggers\"]').value = 'Sleeping'")

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
