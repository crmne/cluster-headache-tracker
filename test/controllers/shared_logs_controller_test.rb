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

  test "offers the shared report as a pdf" do
    get shared_logs_url(token: @share_token.token)

    assert_select "dialog#pdf_report_modal form[action=?]", shared_logs_path(token: @share_token.token, format: :pdf)
  end

  test "downloads the shared report as a pdf with only the sharing user's attacks" do
    get shared_logs_url(token: @share_token.token, format: :pdf, prepared_for: "Dr. Jones", triggers: "Sleep")

    assert_response :success
    assert_equal "application/pdf", response.media_type

    text = pdf_text(response.body)
    assert_includes text, "Dr. Jones"
    assert_includes text, "triggers containing “Sleep”"
    assert_includes text, "Sleeping"
    assert_not_includes text, "Waking up"
  end

  test "does not download a pdf with an expired token" do
    @share_token.update(expires_at: 1.day.ago)

    get shared_logs_url(token: @share_token.token, format: :pdf)

    assert_response :unauthorized
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
end
