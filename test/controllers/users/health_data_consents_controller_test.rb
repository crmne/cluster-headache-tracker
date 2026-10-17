require "test_helper"

class Users::HealthDataConsentsControllerTest < ActionDispatch::IntegrationTest
  NATIVE_USER_AGENT = "ClusterHeadacheTracker; platform=ios; version=2.2.0; build=20200; Hotwire Native iOS; bridge-components: [alert button]"

  setup do
    @user = users(:unconsented)
    sign_in @user
  end

  test "someone who signed up before the checkbox is asked before seeing their logs" do
    get headache_logs_url

    assert_redirected_to health_data_consent_path
    follow_redirect!
    assert_select "h2", "Before you continue"
    assert_select "input[type=checkbox][name=health_data_consent][required]:not([checked])"
    assert_select "label[for=health_data_consent] a[href='#{privacy_policy_path}']", "Privacy Policy"
  end

  test "consenting records when and returns to the page they asked for" do
    get charts_url

    freeze_time do
      post health_data_consent_url, params: { health_data_consent: "1" }

      assert_equal Time.current, @user.reload.consented_at
    end
    assert_redirected_to charts_path

    get headache_logs_url
    assert_response :success
  end

  test "consenting again keeps the first time" do
    post health_data_consent_url, params: { health_data_consent: "1" }
    consented_at = @user.reload.consented_at

    travel 1.day do
      post health_data_consent_url, params: { health_data_consent: "1" }
    end

    assert_equal consented_at, @user.reload.consented_at
  end

  test "continuing without ticking the box records nothing" do
    post health_data_consent_url, params: { health_data_consent: "0" }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", /Tick the box to continue/
    assert_nil @user.reload.consented_at
  end

  test "consenting in the apps rebuilds their tabs" do
    post health_data_consent_url, params: { health_data_consent: "1" }, headers: { "User-Agent" => NATIVE_USER_AGENT }

    assert_redirected_to "/recede_historical_location"
  end

  test "nothing else is processed until they consent" do
    assert_no_difference -> { HeadacheLog.count } do
      post headache_logs_url, params: { headache_log: { start_time: Time.current, intensity: 5 } }
    end
    assert_response :forbidden

    get charts_url(format: :json)
    assert_response :forbidden
  end

  test "they can still delete their account, read the public pages and export their data instead" do
    get settings_url
    assert_response :success
    assert_select "#delete_account form"

    get privacy_policy_url
    assert_response :success

    get headache_log_export_url(format: :csv)
    assert_response :success

    assert_difference -> { User.count }, -1 do
      delete settings_account_url, params: { user: { current_password: "password123" } }
    end
  end

  test "the page offers deleting the account instead" do
    get health_data_consent_url

    assert_select "a[href='#{settings_path(anchor: "delete_account")}']", "Delete my account"
  end

  test "the page is translated" do
    @user.update!(locale: "it")

    get health_data_consent_url

    assert_select "h2", "Prima di continuare"
    assert_select "label[for=health_data_consent]", /Acconsento al trattamento/
  end

  test "people who already consented aren't asked again" do
    sign_in users(:one)

    get health_data_consent_url
    assert_redirected_to headache_logs_path

    get headache_logs_url
    assert_response :success
  end
end
