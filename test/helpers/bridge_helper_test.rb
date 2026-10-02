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
end
