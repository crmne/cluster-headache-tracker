require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "signing up from a translated page saves that language" do
    assert_difference("User.count") do
      post user_registration_url(locale: "it"), params: { user: { username: "nuovo", password: "password123", password_confirmation: "password123" } }
    end

    assert_equal "it", User.find_by(username: "nuovo").locale
    assert_redirected_to headache_logs_path
  end

  test "signing up without an explicit language keeps it automatic" do
    post user_registration_url, params: { user: { username: "auto", password: "password123", password_confirmation: "password123" } }, headers: { "Accept-Language" => "de" }

    assert_nil User.find_by(username: "auto").locale
  end

  test "sign up errors are translated" do
    post user_registration_url(locale: "de"), params: { user: { username: "", password: "password123", password_confirmation: "nope" } }

    assert_response :unprocessable_entity
    assert_select ".alert-error", /Benutzername/
  end

  test "sign up page follows the browser language" do
    get new_user_registration_url, headers: { "Accept-Language" => "es-ES,es;q=0.9,en;q=0.8" }

    assert_select "h2", "Empieza gratis"
  end
end
