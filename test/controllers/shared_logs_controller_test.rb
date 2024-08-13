require "test_helper"

class SharedLogsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get shared_logs_show_url
    assert_response :success
  end
end
