require "application_system_test_case"

class HeadacheLogsTest < ApplicationSystemTestCase
  setup do
    @headache_log = headache_logs(:one)
  end

  test "visiting the index" do
    visit headache_logs_url
    assert_selector "h1", text: "Headache logs"
  end

  test "should create headache log" do
    visit headache_logs_url
    click_on "New headache log"

    fill_in "End time", with: @headache_log.end_time
    fill_in "Intensity", with: @headache_log.intensity
    fill_in "Notes", with: @headache_log.notes
    fill_in "Start time", with: @headache_log.start_time
    fill_in "User", with: @headache_log.user_id
    click_on "Create Headache log"

    assert_text "Headache log was successfully created"
    click_on "Back"
  end

  test "should update Headache log" do
    visit headache_log_url(@headache_log)
    click_on "Edit this headache log", match: :first

    fill_in "End time", with: @headache_log.end_time.to_s
    fill_in "Intensity", with: @headache_log.intensity
    fill_in "Notes", with: @headache_log.notes
    fill_in "Start time", with: @headache_log.start_time.to_s
    fill_in "User", with: @headache_log.user_id
    click_on "Update Headache log"

    assert_text "Headache log was successfully updated"
    click_on "Back"
  end

  test "should destroy Headache log" do
    visit headache_log_url(@headache_log)
    click_on "Destroy this headache log", match: :first

    assert_text "Headache log was successfully destroyed"
  end
end
