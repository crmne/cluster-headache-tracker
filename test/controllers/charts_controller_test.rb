require "test_helper"

class ChartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get charts_url
    assert_response :success
    assert_select "h2", "Headache Intensity Over Time"
  end

  test "shows cycles with the attack calendar and cycle history" do
    get charts_url

    assert_select "#cycles h2", text: /Cycles/
    assert_select "#cycle_count .stat-value", text: "1"
    assert_select "#attack_calendar [data-date='#{Date.current.iso8601}'][data-attacks='1']"
    assert_select "#cycles_table tbody tr", count: 1
    assert_select "#cycles_table tbody tr td", text: "Ongoing"
  end

  test "shows attack-free streaks in the stats" do
    get charts_url

    assert_select "#current_streak .stat-value", text: "0 days"
    assert_select "#longest_streak"
    assert_select "#attack_days"
  end

  test "should require authentication" do
    sign_out @user
    get charts_url
    assert_redirected_to new_user_session_path
  end

  test "should show charts with filtered data" do
    get charts_url, params: {
      start_time: Date.yesterday,
      end_time: Date.tomorrow,
      triggers: "Sleeping"
    }
    assert_response :success
  end

  test "charts follow the browser language" do
    get charts_url, headers: { "Accept-Language" => "de-DE,de;q=0.9,en;q=0.8" }

    assert_response :success
    assert_select "h2", "Schmerzintensität im Verlauf"
    assert_select "script#translations", text: /Attacken pro Tag/
  end
end
