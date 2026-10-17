require "test_helper"

class SettingsPageTest < ActionDispatch::IntegrationTest
  NATIVE_USER_AGENT = "ClusterHeadacheTracker; platform=ios; version=2.2.0; build=20200; Hotwire Native iOS; bridge-components: [alert button]"

  setup do
    sign_in users(:one)
  end

  test "settings offer the disclaimer, the legal pages and account deletion" do
    get settings_url

    assert_select "#about", /not medical advice/
    assert_select "#about a[href='#{privacy_policy_path}']"
    assert_select "#about a[href='mailto:#{AiVisibleContent::CONTACT_EMAIL}']"
    assert_select "#delete_account form[action='#{settings_account_path}'] input[name='_method'][value=delete]"
  end

  test "the apps can delete the account too" do
    get settings_url, headers: { "User-Agent" => NATIVE_USER_AGENT }

    assert_select "#delete_account input[type=password][name='user[current_password]']"
    assert_select "#delete_account form[data-bridge-confirm='Delete account']"
  end
end
