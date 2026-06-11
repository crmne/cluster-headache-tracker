require "application_system_test_case"

class HeadacheLogsTest < ApplicationSystemTestCase
  include ActionView::RecordIdentifier

  setup do
    @user = users(:one)
    @user.update!(welcome_seen_at: Time.current, last_seen_changelog: ChangelogEntry.current.key)
    sign_in @user
  end

  test "visiting the index" do
    visit headache_logs_url
    assert_selector "div.navbar-center", text: "Headache Logs"
    assert_selector ".stats", count: 1
    assert_selector ".card", minimum: 1
  end



  test "marking ongoing headache as complete" do
    # Create an ongoing headache log
    log = headache_logs(:one)
    end_time = log.end_time
    log.update(end_time: nil)

    # Visit the headache logs page
    visit headache_logs_url

    # Verify we see the "Ongoing Headache" alert (not in the card)
    assert_text "Ongoing Headache"

    # Click the Edit button in the ongoing headache alert (find the specific one with role="alert")
    within("div[role='alert'].alert-warning") do
      click_on "Edit"
    end
    assert_current_path edit_headache_log_path(log)

    # Fill in the end time
    fill_in "headache_log[end_time]", with: end_time

    # Submit the form and wait for the update
    click_button "Update Headache log"

    # Verify the success message and that "Ongoing" is no longer present
    # Check that the ongoing headache is now complete
    assert_no_text "Ongoing Headache"
    # The log should now show an end time
    assert_selector ".radial-progress", text: log.intensity.to_s
  end
end
