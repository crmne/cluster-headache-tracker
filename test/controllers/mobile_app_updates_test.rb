require "test_helper"

class MobileAppUpdatesTest < ActionDispatch::IntegrationTest
  GITHUB_ANDROID = "ClusterHeadacheTracker; platform=android; version=2.1.0; build=20100; Hotwire Native Android; bridge-components: [button]"
  PLAY_ANDROID = "ClusterHeadacheTracker; platform=android; version=2.1.0; build=20100; store=play; Hotwire Native Android; bridge-components: [button]"
  IOS = "ClusterHeadacheTracker; platform=ios; version=2.1.0; build=20100; Hotwire Native iOS; bridge-components: [button]"

  setup do
    sign_in users(:one)
    @apk_url = "https://github.com/crmne/cluster-headache-tracker-android/releases/download/v2.2.0/cluster-headache-tracker.apk"
    MobileReleaseSnapshot.create!(platform: "android", latest_version: "2.2.0", release_url: @apk_url,
      release_notes_url: "https://github.com/crmne/cluster-headache-tracker-android/releases/tag/v2.2.0")
    MobileReleaseSnapshot.create!(platform: "ios", latest_version: "2.2.0",
      release_url: "https://github.com/crmne/cluster-headache-tracker-ios/releases/tag/v2.2.0")
  end

  test "apps installed from GitHub are offered the new APK" do
    get headache_logs_url, headers: { "User-Agent" => GITHUB_ANDROID }

    assert_select "#appUpdateModal a[href='#{@apk_url}']"
  end

  test "Google Play installs never hear about GitHub releases" do
    get headache_logs_url, headers: { "User-Agent" => PLAY_ANDROID }

    assert_select "#appUpdateModal", count: 0
    assert_select "a[href='#{@apk_url}']", count: 0
  end

  test "Google Play installs that must update are sent to Google Play" do
    MobileReleaseSnapshot.find_by(platform: "android").update!(minimum_supported_version: "2.2.0")

    get headache_logs_url, headers: { "User-Agent" => PLAY_ANDROID }

    assert_select "#appUpdateModal a[href='#{AppConstants::PLAY_STORE_URL}']"
    assert_select "#appUpdateModal a[href*='github.com']", count: 0
  end

  test "the iOS app isn't sent to GitHub, even when it must update" do
    MobileReleaseSnapshot.find_by(platform: "ios").update!(minimum_supported_version: "2.2.0")

    get headache_logs_url, headers: { "User-Agent" => IOS }

    assert_select "#appUpdateModal", count: 0
  end
end
