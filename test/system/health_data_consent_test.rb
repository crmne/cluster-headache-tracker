require "application_system_test_case"

class HealthDataConsentTest < ApplicationSystemTestCase
  test "signing up takes ticking the consent box" do
    visit new_user_registration_url
    fill_in "Username", with: "newpatient"
    fill_in "user[password]", with: "password123"
    fill_in "user[password_confirmation]", with: "password123"
    click_button "Start Free Tracking"

    # The browser won't submit the form while the required box is unticked
    assert_current_path new_user_registration_path

    check "health_data_consent"
    click_button "Start Free Tracking"

    assert_current_path headache_logs_path
    assert User.find_by(username: "newpatient").consented?
  end

  test "an existing account is asked once, then carries on" do
    user = users(:unconsented)
    user.update!(welcome_seen_at: Time.current, last_seen_changelog: ChangelogEntry.current.key)
    sign_in user

    visit charts_url
    assert_text "Before you continue"

    check "health_data_consent"
    click_button "Continue"

    assert_current_path charts_path
    assert user.reload.consented?
  end
end
