require "test_helper"

class WidgetStatusBridgeTest < ActionDispatch::IntegrationTest
  NATIVE_USER_AGENT = "ClusterHeadacheTracker; platform=android; version=2.2.0; build=20200; Hotwire Native Android; bridge-components: [widget-status]"

  test "signed-in pages hand the apps the attack status" do
    sign_in users(:one)

    get headache_logs_url, headers: { "User-Agent" => NATIVE_USER_AGENT }

    assert_select "#bridge_widget_status[data-bridge--widget-status-payload-value]"
    assert_select "#bridge_widget_status[data-bridge--widget-status-signed-out-value=true]", count: 0
  end

  test "signed-out pages tell the apps to clear their widgets" do
    get new_user_session_url, headers: { "User-Agent" => NATIVE_USER_AGENT }

    assert_select "#bridge_widget_status[data-bridge--widget-status-signed-out-value=true]"
    assert_select "#bridge_widget_status[data-bridge--widget-status-payload-value]", count: 0
  end

  test "browsers get no bridge element" do
    get new_user_session_url

    assert_select "#bridge_widget_status", count: 0
  end
end
