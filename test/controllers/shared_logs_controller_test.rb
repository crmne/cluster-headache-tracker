require "test_helper"

class SharedLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @share_token = share_tokens(:one)
  end

  test "should show shared logs with valid token" do
    get shared_logs_url(token: @share_token.token)
    assert_response :success
    assert_select ".navbar-center", text: "Doctor's view"
    assert_select ".grid", minimum: 1
  end

  test "should not show shared logs with invalid token" do
    get shared_logs_url(token: "invalid_token")
    assert_response :unauthorized
    assert_match /invalid or has expired/, response.body
  end

  test "should not show shared logs with expired token" do
    @share_token.update(expires_at: 1.day.ago)
    get shared_logs_url(token: @share_token.token)
    assert_response :unauthorized
    assert_match /invalid or has expired/, response.body
  end

  test "never includes photos" do
    headache_logs(:one).photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")

    get shared_logs_url(token: @share_token.token)

    assert_response :success
    assert_select "img[src*='/photos/']", count: 0
  end
end
