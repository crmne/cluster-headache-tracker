require "application_system_test_case"

class ChangelogModalTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @user.update!(has_seen_welcome: true, last_seen_changelog: nil)
    sign_in @user
  end

  test "continuing to the app dismisses the changelog" do
    visit headache_logs_url

    assert_selector "dialog#changelogModal", visible: :all

    click_button "Continue to App"

    assert_no_selector "dialog#changelogModal", visible: :all
    assert_equal ChangelogEntry.current.key, @user.reload.last_seen_changelog
  end

  test "closing the changelog dialog dismisses it" do
    visit headache_logs_url

    assert_selector "dialog#changelogModal", visible: :all

    page.execute_script("document.querySelector('#changelogModal .modal-backdrop').requestSubmit()")

    assert_no_selector "dialog#changelogModal", visible: :all
    assert_equal ChangelogEntry.current.key, @user.reload.last_seen_changelog
  end
end
