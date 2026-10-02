require "test_helper"

class HeadacheLogPrintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "print view is in the user's language" do
    @user.update!(locale: "de")

    get headache_log_print_url

    assert_response :success
    assert_select "h1", "Clusterkopfschmerz-Bericht für #{@user.username}"
    assert_select "p", text: /am #{I18n.l(Date.current, format: :long_date, locale: :de)}/
  end

  test "print view honors the 24-hour preference" do
    @user.update!(time_format: "24h")
    @user.headache_logs.create!(start_time: Time.zone.parse("2026-03-04 19:05"), end_time: Time.zone.parse("2026-03-04 20:15"), intensity: 8)

    get headache_log_print_url

    assert_response :success
    assert_includes response.body, "19:05"
    assert_not_includes response.body, "7:05 PM"
  end

  test "print view honors the 12-hour preference in other languages" do
    @user.update!(locale: "it", time_format: "12h")
    @user.headache_logs.create!(start_time: Time.zone.parse("2026-03-04 19:05"), end_time: Time.zone.parse("2026-03-04 20:15"), intensity: 8)

    get headache_log_print_url

    assert_response :success
    assert_includes response.body, "7:05 PM"
  end
end
