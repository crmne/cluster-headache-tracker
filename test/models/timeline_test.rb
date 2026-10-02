require "test_helper"

class TimelineTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "attacks and standalone doses newest first, grouped by day, with attack doses inside their attack" do
    timeline = Timeline.new(@user)

    assert_equal [ headache_logs(:one), medication_doses(:lithium_yesterday), headache_logs(:three) ], timeline.entries
    assert_equal timeline.entries.map { |entry| (entry.try(:start_time) || entry.taken_at).to_date }.uniq, timeline.days.map(&:date)
    assert_nil timeline.next_before
  end

  test "pages back with a time cursor" do
    first_page = Timeline.new(@user, limit: 2)
    assert_equal [ headache_logs(:one), medication_doses(:lithium_yesterday) ], first_page.entries

    second_page = Timeline.new(@user, before: first_page.next_before, limit: 2)
    assert_equal [ headache_logs(:three) ], second_page.entries
    assert_nil second_page.next_before
  end
end
