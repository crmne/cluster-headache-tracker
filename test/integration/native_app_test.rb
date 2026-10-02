require "test_helper"

class NativeAppTest < ActionDispatch::IntegrationTest
  BROWSER = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

  test "signed-out native apps get a 401 to present their own sign-in" do
    get headache_logs_url, headers: { "User-Agent" => native_user_agent(platform: "ios", version: "1.2.0") }
    assert_response :unauthorized

    get headache_logs_url, headers: { "User-Agent" => "#{BROWSER} Turbo Native Android" }
    assert_response :unauthorized
  end

  test "signed-out browsers are redirected to sign in" do
    get headache_logs_url, headers: { "User-Agent" => BROWSER }

    assert_redirected_to new_user_session_url
  end

  test "native apps with tabs hide the web navigation" do
    sign_in users(:one)

    [ "1.0.8", "1.1.0", "2.0.0" ].each do |version|
      get headache_logs_url, headers: { "User-Agent" => native_user_agent(platform: "ios", version: version) }

      assert_select "nav.navbar.hidden", 1, version
      assert_select ".dock", 0, version
    end
  end

  test "native apps from before tabs keep the web dock" do
    sign_in users(:one)

    get headache_logs_url, headers: { "User-Agent" => native_user_agent(platform: "android", version: "1.0.7") }

    assert_select "nav.navbar.hidden", 0
    assert_select ".dock", 1
  end

  test "legacy user agents with the version after the app name" do
    sign_in users(:one)

    get headache_logs_url, headers: { "User-Agent" => "#{BROWSER} ClusterHeadacheTracker/1.0.9.12; Hotwire Native iOS" }

    assert_select "nav.navbar.hidden", 1
  end

  test "browsers get the full web chrome" do
    sign_in users(:one)

    get headache_logs_url, headers: { "User-Agent" => BROWSER }

    assert_select "nav.navbar.hidden", 0
    assert_select ".dock", 1
  end

  test "native form pages hide the dock so the native buttons drive the form" do
    sign_in users(:one)

    get new_medication_url, headers: { "User-Agent" => native_user_agent(platform: "android", version: "1.0.7") }

    assert_select ".dock", 0
    assert_select "[data-controller='bridge--button'][data-bridge-title='Save']"
  end

  test "our recede historical location route wins over turbo-rails'" do
    assert_recognizes({ controller: "recede_historical_locations", action: "show" }, "/recede_historical_location")
  end

  private
    def native_user_agent(platform:, version:)
      "ClusterHeadacheTracker; platform=#{platform}; version=#{version}; build=1; Hotwire Native #{platform == "ios" ? "iOS" : "Android"}; #{BROWSER}"
    end
end
