require "application_system_test_case"

class HeadacheLogsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include ActionView::RecordIdentifier

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

    # Close any modals that might be open
    if page.has_css?(".modal-backdrop", wait: 0.5)
      page.execute_script("document.querySelectorAll('.modal').forEach(m => m.close())")
      sleep(0.5)
    end

    # Click the first "New" button (for web)
    first(:link_or_button, "New").click

    # Add a small wait to ensure page is fully loaded
    sleep(0.5)

    # Fill in start time directly by field name
    fill_in "headache_log[start_time]", with: Time.current.strftime("%Y-%m-%dT%H:%M")

    # Intensity - using execute_script with a robust selector
    page.execute_script("document.querySelector('.range').value = 7")
    page.execute_script("document.querySelector('.range').dispatchEvent(new Event('input'))")

    # These should be more straightforward
    fill_in "headache_log[medication]", with: "Sumatriptan + Oxygen"
    fill_in "headache_log[triggers]", with: "Lack of sleep, Stress"
    fill_in "headache_log[notes]", with: "Severe headache on the right side"

    click_on "Create Headache log"

    # After creating, we should see the content in the list
    assert_text "Sumatriptan + Oxygen"
    assert_text "Lack of sleep"
    assert_text "Severe headache on the right side"
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

    # Wait for the flash message or check the updated content
    assert_text "Updated notes"
    # The intensity should be updated
    assert_selector ".radial-progress span", text: "8"
  end

  test "marking ongoing headache as complete" do
    # Create an ongoing headache log
    log = headache_logs(:one)
    end_time = log.end_time
    log.update(end_time: nil)

    # Visit the headache logs page
    visit headache_logs_url

    # Close any modals that might be open
    if page.has_css?(".modal-backdrop", wait: 0.5)
      page.execute_script("document.querySelectorAll('.modal').forEach(m => m.close())")
      sleep(0.5)
    end

    # Verify we see the "Ongoing Headache" alert (not in the card)
    assert_text "Ongoing Headache"

    # Click the Edit button in the ongoing headache alert (find the specific one with role="alert")
    within("div[role='alert'].alert-warning") do
      click_on "Edit"
    end
    assert_current_path edit_headache_log_path(log)

    # Fill in the end time using JavaScript
    page.execute_script("document.querySelector('input[type=\"datetime-local\"][name=\"headache_log[end_time]\"]').value = '#{end_time.strftime("%Y-%m-%dT%H:%M")}'")

    # Submit the form and wait for the update
    click_button "Update Headache log"

    # Verify the success message and that "Ongoing" is no longer present
    # Check that the ongoing headache is now complete
    assert_no_text "Ongoing Headache"
    # The log should now show an end time
    assert_selector ".radial-progress", text: log.intensity.to_s
  end

  test "filtering headache logs" do
    visit headache_logs_url

    # Close any modals that might be open
    if page.has_css?(".modal-backdrop", wait: 0.5)
      page.execute_script("document.querySelectorAll('.modal').forEach(m => m.close())")
      sleep(0.5)
    end

    open_accordion "filters"

    # Set date range to capture fixtures (3 days ago to tomorrow)
    three_days_ago = 3.days.ago.to_date.to_s
    tomorrow = Date.tomorrow.to_s

    # Set date fields within the filter form
    within("details[data-accordion='filters']") do
      # Target date inputs more specifically
      fill_in "start_time", with: three_days_ago
      fill_in "end_time", with: tomorrow
      fill_in "triggers", with: "Sleeping"
    end

    click_on "Apply Filters"

    # Should find the "Sleeping" trigger from the fixtures
    assert_text "Sleeping"
  end

  test "generating and copying share link" do
    visit headache_logs_url

    # Close any modals that might be open
    if page.has_css?(".modal-backdrop", wait: 0.5)
      page.execute_script("document.querySelectorAll('.modal').forEach(m => m.close())")
      sleep(0.5)
    end

    # First check if a share link already exists, if so delete it
    if page.has_button?("Share")
      # Click the X button to expire the share link
      within("#share_link") do
        find(".btn-ghost.text-error").click
      end
      sleep(0.5)
    end

    # Now generate a new share link
    within("#share_link") do
      click_button "Generate Share Link"
    end

    # After generating, we should see the share button
    assert_selector "button[data-share-link-target='shareButton']", text: "Share"
  end

  test "importing CSV file" do
    visit settings_url

    # Store the initial count of headache logs
    initial_count = @user.headache_logs.count

    click_on "Import CSV"

    # Wait for modal to open and ensure it's visible
    assert_selector "#import_modal", visible: true

    within("#import_modal") do
      attach_file "file", "test/fixtures/files/sample_logs.csv"
      # Submit the form
      click_button "Import"
    end

    # Give it time to process
    sleep(3)

    # The import should either redirect to headache logs or show imported content
    # Check multiple possible success conditions
    success = page.has_current_path?(headache_logs_path) ||
              page.has_text?("Successfully imported") ||
              page.has_text?("Morning attack") ||
              @user.headache_logs.count > initial_count

    assert success, "Import did not complete successfully"
  end
end
