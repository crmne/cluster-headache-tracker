require "test_helper"

class ChangelogEntryTest < ActiveSupport::TestCase
  test "current entry treats legacy acknowledgements as seen" do
    user = User.new(last_seen_changelog: "v2.1.0")

    assert ChangelogEntry.current.seen_by?(user)
  end

  test "current entry exposes the configured changelog key" do
    assert_equal AppConstants::CHANGELOG_KEY, ChangelogEntry.current.key
  end
end
