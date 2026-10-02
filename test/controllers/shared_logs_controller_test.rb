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

  test "shared logs are shown in the doctor's language" do
    get shared_logs_url(token: @share_token.token), headers: { "Accept-Language" => "it-IT,it;q=0.9" }

    assert_response :success
    assert_select ".navbar-center", text: "Vista per il medico"
    assert_select "h1", text: "Report sulla cefalea a grappolo di #{@user.username}"
  end

  test "invalid share link message follows the doctor's language" do
    get shared_logs_url(token: "invalid_token"), headers: { "Accept-Language" => "es" }

    assert_response :unauthorized
    assert_equal "Este enlace para compartir no es válido o ha caducado.", response.body
  end
end
