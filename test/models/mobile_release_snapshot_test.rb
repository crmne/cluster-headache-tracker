require "test_helper"

class MobileReleaseSnapshotTest < ActiveSupport::TestCase
  test "reports when a newer version is available" do
    snapshot = MobileReleaseSnapshot.new(platform: "android", latest_version: "2.1.0")

    assert snapshot.update_available_for?("2.0.0")
    assert_not snapshot.update_available_for?("2.1.0")
  end

  test "reports when a minimum version requires an update" do
    snapshot = MobileReleaseSnapshot.new(platform: "android", minimum_supported_version: "2.0.5")

    assert snapshot.update_required_for?("2.0.0")
    assert_not snapshot.update_required_for?("2.0.5")
  end

  test "ignores invalid version strings" do
    snapshot = MobileReleaseSnapshot.new(platform: "android", latest_version: "invalid")

    assert_not snapshot.update_available_for?("2.0.0")
  end

  test "sync_all stores release metadata from github release and tag sources" do
    stubbing_github_json do
      assert_difference "MobileReleaseSnapshot.count", 2 do
        MobileReleaseSnapshot.sync_all
      end
    end

    android_snapshot = MobileReleaseSnapshot.find_by!(platform: "android")
    ios_snapshot = MobileReleaseSnapshot.find_by!(platform: "ios")

    assert_equal "2.1.0", android_snapshot.latest_version
    assert_equal "https://example.com/android.apk", android_snapshot.release_url
    assert_equal "github_release", android_snapshot.source

    assert_equal "2.1.0", ios_snapshot.latest_version
    assert_equal "github_tag", ios_snapshot.source
    assert_match %r{cluster-headache-tracker-ios/tree/v2\.1\.0}, ios_snapshot.release_notes_url
  end

  private
    def stubbing_github_json(&block)
      MobileReleaseSnapshot.singleton_class.class_eval do
        alias_method :original_github_json, :github_json

        define_method(:github_json) do |repository:, path:|
          case [ repository, path ]
          when [ AppConstants::ANDROID_GITHUB_REPOSITORY, "/releases/latest" ]
            {
              "tag_name" => "v2.1.0",
              "html_url" => "https://github.com/crmne/cluster-headache-tracker-android/releases/tag/v2.1.0",
              "assets" => [
                {
                  "name" => "cluster-headache-tracker-debug.apk",
                  "browser_download_url" => "https://example.com/android-debug.apk"
                },
                {
                  "name" => "cluster-headache-tracker.apk",
                  "browser_download_url" => "https://example.com/android.apk"
                }
              ]
            }
          when [ AppConstants::IOS_GITHUB_REPOSITORY, "/tags?per_page=1" ]
            [ { "name" => "v2.1.0" } ]
          end
        end
      end

      block.call
    ensure
      MobileReleaseSnapshot.singleton_class.class_eval do
        alias_method :github_json, :original_github_json
        remove_method :original_github_json
        private :github_json
      end
    end
end
