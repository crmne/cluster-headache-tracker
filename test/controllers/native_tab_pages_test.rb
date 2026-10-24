require "test_helper"

# The Android app floats its tabs and New log over a tab's first page, which
# leaves room for them under its last row.
class NativeTabPagesTest < ActionDispatch::IntegrationTest
  ANDROID = "ClusterHeadacheTracker; platform=android; version=2.5.0; build=20500; Hotwire Native Android; bridge-components: [button]"
  IOS = "ClusterHeadacheTracker; platform=ios; version=2.5.0; build=20500; Hotwire Native iOS; bridge-components: [button]"

  setup do
    sign_in users(:one)
  end

  test "tabs' first pages leave room for the floating toolbar in the Android app" do
    [ headache_logs_url, charts_url, settings_url, new_feedback_url ].each do |url|
      get url, headers: { "User-Agent" => ANDROID }
      # Feedback sends someone who already answered on to its thank-you page, a tab's first page too.
      follow_redirect!(headers: { "User-Agent" => ANDROID }) if response.redirect?
      assert_select "main.pb-28", { count: 1 }, url
    end
  end

  test "pages pushed on top, iOS, and the website don't" do
    get new_headache_log_url, headers: { "User-Agent" => ANDROID }
    assert_select "main.pb-28", count: 0

    get headache_logs_url, headers: { "User-Agent" => IOS }
    assert_select "main.pb-28", count: 0

    get headache_logs_url
    assert_select "main.pb-28", count: 0
  end

  test "the Android app gets no New button in its bar: New log floats beside the tabs" do
    [ headache_logs_url, charts_url ].each do |url|
      get url, headers: { "User-Agent" => ANDROID }
      assert_select "[data-controller='bridge--button'][href='/headache_logs/new']", { count: 0 }, url

      get url, headers: { "User-Agent" => IOS }
      assert_select "[data-controller='bridge--button'][href='/headache_logs/new']", { count: 1 }, url
    end
  end
end
