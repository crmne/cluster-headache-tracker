require "test_helper"

class BridgeHelperTest < ActionView::TestCase
  NATIVE_USER_AGENT = "ClusterHeadacheTracker; platform=ios; version=1.2.0; build=12; Hotwire Native iOS; Turbo Native iOS; bridge-components: [alert form review-prompt toast]"

  test "reads the bridge components the app registered from its user agent" do
    request.user_agent = NATIVE_USER_AGENT

    assert bridge_component_supported?("form")
    assert bridge_component_supported?("review-prompt")
    assert_not bridge_component_supported?("menu")
    assert_not bridge_component_supported?("rev")
  end

  test "browsers support no bridge components" do
    request.user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"

    assert_not bridge_component_supported?("toast")
  end

  test "maps flash types to haptic feedback" do
    assert_equal "success", flash_haptic_feedback(:notice)
    assert_equal "warning", flash_haptic_feedback("alert")
    assert_equal "error", flash_haptic_feedback(:error)
    assert_nil flash_haptic_feedback(:generate_link)
  end

  test "widget status while an attack is ongoing" do
    user = users(:two)
    ongoing = user.headache_logs.create!(start_time: 20.minutes.ago.change(usec: 0), intensity: 7)

    status = widget_status_payload(user)

    assert status[:ongoing]
    assert_equal ongoing.start_time.iso8601, status[:startedAt]
    assert_equal ongoing.start_time.iso8601, status[:lastAttackAt]
    assert_equal 0, status[:attackFreeDays]
    assert_equal user.headache_logs.today.count, status[:attacksToday]
    assert_equal "en", status[:locale]
  end

  test "widget status counts attack-free days since the last attack ended" do
    user = users(:two)
    user.headache_logs.update_all(start_time: 3.days.ago.beginning_of_day + 1.hour, end_time: 3.days.ago.beginning_of_day + 2.hours)

    status = widget_status_payload(user)

    assert_not status[:ongoing]
    assert_nil status[:startedAt]
    assert_equal 3, status[:attackFreeDays]
    assert_equal 0, status[:attacksToday]
  end

  test "widget status without any attacks" do
    user = User.create!(username: "newcomer", password: "password123")

    assert_equal({ ongoing: false, startedAt: nil, lastAttackAt: nil, attackFreeDays: 0, attacksToday: 0, locale: "en" }, widget_status_payload(user))
  end
end
