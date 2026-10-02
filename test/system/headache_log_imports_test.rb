require "application_system_test_case"

class HeadacheLogImportsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @user.update!(welcome_seen_at: Time.current, last_seen_changelog: ChangelogEntry.current.key)
    sign_in @user
  end

  test "importing a Migraine Buddy export says which format was detected and what was skipped" do
    visit settings_url
    click_on "Import"

    within "#import_modal" do
      assert_text "Migraine Buddy CSV exports are recognized automatically"
      attach_file "file", file_fixture("migraine_buddy_mixed.csv")
      click_on "Import"
    end

    assert_selector "div.navbar-center", text: "Headache Logs"
    assert_text "Detected a Migraine Buddy export. Imported 4 headache logs. Skipped 3 rows that couldn't be read."
  end
end
