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

  test "should show barometric pressure in shared logs" do
    get shared_logs_url(token: @share_token.token)
    assert_select "td", /1008.5 hPa/
    assert_select "canvas#pressureChart"
  end

  test "shared logs show cycles for the doctor" do
    get shared_logs_url(token: @share_token.token)

    assert_select "#attack_streaks"
    assert_select "#cycles #cycles_table tbody tr", count: 1
    assert_select "#attack_calendar"
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

  test "never includes photos" do
    headache_logs(:one).photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")

    get shared_logs_url(token: @share_token.token)

    assert_response :success
    assert_select "img[src*='/photos/']", count: 0
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
