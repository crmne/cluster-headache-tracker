require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "signing up from a translated page saves that language" do
    assert_difference("User.count") do
      post user_registration_url(locale: "it"), params: { user: { username: "nuovo", password: "password123", password_confirmation: "password123", health_data_consent: "1" } }
    end

    assert_equal "it", User.find_by(username: "nuovo").locale
    assert_redirected_to headache_logs_path
  end

  test "signing up without an explicit language keeps it automatic" do
    post user_registration_url, params: { user: { username: "auto", password: "password123", password_confirmation: "password123", health_data_consent: "1" } }, headers: { "Accept-Language" => "de" }

    assert_nil User.find_by(username: "auto").locale
  end

  test "signing up records the consent to processing health data" do
    freeze_time do
      post user_registration_url, params: { user: { username: "consenting", password: "password123", password_confirmation: "password123", health_data_consent: "1" } }

      assert_equal Time.current, User.find_by(username: "consenting").consented_at
    end
  end

  test "signing up requires the consent to processing health data" do
    assert_no_difference("User.count") do
      post user_registration_url, params: { user: { username: "unsure", password: "password123", password_confirmation: "password123", health_data_consent: "0" } }
    end

    assert_response :unprocessable_entity
    assert_select ".alert-error", /consent to the processing of your health data/
  end

  test "signing up without the consent field at all doesn't create an account either" do
    assert_no_difference("User.count") do
      post user_registration_url, params: { user: { username: "sneaky", password: "password123", password_confirmation: "password123" } }
    end

    assert_response :unprocessable_entity
  end

  test "sign up page asks for consent with an unticked, required checkbox linking the privacy policy" do
    get new_user_registration_url

    assert_select "input[type=checkbox][name='user[health_data_consent]'][required]:not([checked])"
    assert_select "label[for=health_data_consent]", /I consent to Cluster Headache Tracker processing the health data I enter/ do
      assert_select "a[href='#{privacy_policy_path}']", "Privacy Policy"
    end
  end

  test "the consent checkbox is translated" do
    get new_user_registration_url, headers: { "Accept-Language" => "de" }

    assert_select "label[for=health_data_consent]", /Ich willige ein/ do
      assert_select "a[href='#{privacy_policy_path(locale: "de")}']", "Datenschutzerklärung"
    end
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

  test "sign up page says the app is no substitute for medical advice and links the privacy policy" do
    get new_user_registration_url

    assert_select "p", /tracking tool, not medical advice/
    assert_select "a[href='#{privacy_policy_path}']", "Privacy Policy"
  end
end
