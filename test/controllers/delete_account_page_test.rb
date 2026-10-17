require "test_helper"

class DeleteAccountPageTest < ActionDispatch::IntegrationTest
  test "explains how to delete an account without signing in" do
    get delete_account_url

    assert_response :success
    assert_select "h1", "Delete your Cluster Headache Tracker account"
    assert_select "h2", "In the iOS or Android app"
    assert_select "a[href^='mailto:#{AiVisibleContent::CONTACT_EMAIL}']"
  end

  test "is translated" do
    get "/de/delete-account"

    assert_select "h1", "Ihr Konto bei Cluster Headache Tracker löschen"
  end

  test "the privacy policy links to it" do
    get privacy_policy_url

    assert_select "a[href='#{delete_account_path}']"
  end
end
