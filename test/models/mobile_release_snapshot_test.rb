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
end
