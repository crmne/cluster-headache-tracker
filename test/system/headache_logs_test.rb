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
    assert_selector "#headache_stats .stats", count: 2
    assert_selector "#attack_streaks"
    assert_selector ".card", minimum: 1
  end



  test "logging barometric pressure" do
    visit new_headache_log_url
    fill_in "Barometric pressure", with: "1004.6"
    click_button "Create Headache log"

    page.document.synchronize do
      raise Capybara::ExpectationNotMet unless @user.headache_logs.exists?(barometric_pressure: 1004.6)
    end

    visit headache_logs_url
    assert_text "1004.6 hPa"
  end

  test "opening the pdf report download" do
    visit headache_logs_url

    within("#share_link") { click_button "Download PDF" }

    within("dialog#pdf_report_modal[open]") do
      fill_in "Name shown on the report", with: "Alex Smith"
      fill_in "Prepared for", with: "Dr. Jones"
      find(".modal-action button", text: "Cancel").click
    end

    assert_no_selector "dialog#pdf_report_modal[open]"
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

  test "the new log form shows times and descriptions in the user's language and clock" do
    @user.update!(locale: "de", time_format: "24h")

    visit new_headache_log_url
    assert_selector "h3", text: "Beginn"

    fill_in "headache_log[start_time]", with: Time.zone.parse("2026-03-14 19:05")
    assert_selector "[data-time-target=readout]", text: /14\. März? · 19:05/
    assert_no_selector "[data-time-target=readout]", text: /PM/

    find("input[type=range]").set(9)
    assert_text "als würde das Auge gleich platzen"
  end

  test "the new log form readout follows a 12-hour preference" do
    @user.update!(time_format: "12h")

    visit new_headache_log_url
    fill_in "headache_log[start_time]", with: Time.zone.parse("2026-03-14 19:05")
    assert_selector "[data-time-target=readout]", text: /7:05[[:space:]]PM/
  end
end
