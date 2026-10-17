require "test_helper"

class SponsorLinksTest < ActionDispatch::IntegrationTest
  SPONSORS = "https://github.com/sponsors/crmne"
  PLAY_ANDROID = "ClusterHeadacheTracker; platform=android; version=2.2.0; build=20200; store=play; Hotwire Native Android; bridge-components: [button]"
  GITHUB_ANDROID = "ClusterHeadacheTracker; platform=android; version=2.2.0; build=20200; Hotwire Native Android; bridge-components: [button]"
  IOS = "ClusterHeadacheTracker; platform=ios; version=2.2.0; build=20200; Hotwire Native iOS; bridge-components: [button]"

  setup do
    sign_in users(:one)
  end

  test "the website and GitHub APK installs offer sponsoring" do
    get thank_you_feedback_url
    assert_select "a[href='#{SPONSORS}']"

    get thank_you_feedback_url, headers: { "User-Agent" => GITHUB_ANDROID }
    assert_select "a[href='#{SPONSORS}']"
  end

  test "store builds never link to donations outside their store" do
    [ PLAY_ANDROID, IOS ].each do |user_agent|
      get new_feedback_url, headers: { "User-Agent" => user_agent }
      assert_select "a[href='#{SPONSORS}']", count: 0

      get thank_you_feedback_url, headers: { "User-Agent" => user_agent }
      assert_select "a[href='#{SPONSORS}']", count: 0

      get headache_logs_url, headers: { "User-Agent" => user_agent }
      assert_select "a[href='#{SPONSORS}']", count: 0
    end
  end
end
