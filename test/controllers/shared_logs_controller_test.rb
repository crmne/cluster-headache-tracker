require "test_helper"

class SharedLogsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @user.generate_share_token
  end

  test "should get show" do
    get shared_logs_url @user.share_tokens.last.token
    assert_response :success
  end
end
