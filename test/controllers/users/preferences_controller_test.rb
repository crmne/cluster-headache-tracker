require "test_helper"

class Users::PreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "settings offer the language and time format preferences" do
    get settings_url

    assert_select "#preferences select[name='user[locale]'] option", count: 5
    assert_select "#preferences input[type=radio][name='user[time_format]']", count: 3
  end

  test "saves the language and time format" do
    patch settings_preferences_url, params: { user: { locale: "de", time_format: "12h" } }

    assert_redirected_to settings_url
    assert_equal "de", @user.reload.locale
    assert_equal "12h", @user.time_format
    assert_equal "Ihre Sprach- und Zeiteinstellungen wurden gespeichert.", flash[:notice]
  end

  test "blank choices go back to automatic" do
    @user.update!(locale: "it", time_format: "24h")

    patch settings_preferences_url, params: { user: { locale: "", time_format: "" } }

    assert_nil @user.reload.locale
    assert_nil @user.time_format
  end

  test "rejects unsupported languages" do
    patch settings_preferences_url, params: { user: { locale: "xx" } }

    assert_response :unprocessable_entity
    assert_nil @user.reload.locale
  end

  test "requires sign in" do
    sign_out @user

    patch settings_preferences_url, params: { user: { locale: "de" } }

    assert_redirected_to new_user_session_url
  end
end
