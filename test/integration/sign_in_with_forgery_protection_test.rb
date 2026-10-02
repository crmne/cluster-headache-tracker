require "test_helper"

class SignInWithForgeryProtectionTest < ActionDispatch::IntegrationTest
  setup do
    @forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @forgery_protection
  end

  test "signing in with the form's authenticity token keeps the session" do
    user = users(:one)
    user.update!(password: "a-long-password", password_confirmation: "a-long-password")

    get new_user_session_url
    token = css_select("form#new_user input[name=authenticity_token]").first["value"]

    post user_session_url, params: { authenticity_token: token, user: { username: user.username, password: "a-long-password" } }
    get headache_logs_url

    assert_response :success
  end
end
