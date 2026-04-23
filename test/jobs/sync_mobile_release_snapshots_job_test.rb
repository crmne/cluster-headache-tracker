require "test_helper"

class SyncMobileReleaseSnapshotsJobTest < ActiveJob::TestCase
  test "syncs release metadata from github release and tag sources" do
    job = SyncMobileReleaseSnapshotsJob.new

    job.singleton_class.define_method(:github_json) do |repository:, path:|
      case [ repository, path ]
      when [ AppConstants::ANDROID_GITHUB_REPOSITORY, "/releases/latest" ]
        {
          "tag_name" => "v2.1.0",
          "html_url" => "https://github.com/crmne/cluster-headache-tracker-android/releases/tag/v2.1.0",
          "assets" => [
            {
              "name" => "cluster-headache-tracker.apk",
              "browser_download_url" => "https://example.com/android.apk"
            }
          ]
        }
      when [ AppConstants::IOS_GITHUB_REPOSITORY, "/releases/latest" ]
        nil
      when [ AppConstants::IOS_GITHUB_REPOSITORY, "/tags?per_page=1" ]
        [ { "name" => "v2.1.0" } ]
      else
        nil
      end
    end

    assert_difference "MobileReleaseSnapshot.count", 2 do
      job.perform
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
end
