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

  test "shows how well each medication worked and preventive adherence" do
    get charts_url

    assert_select "#medication_insights" do
      assert_select "tr", text: /Oxygen.*100%/m
      assert_select "canvas#adherenceChart"
    end
    assert_select "[data-charts-medication-colors-value*=?]", "#0ea5e9"
  end

  test "time charts get the remission periods between cycles" do
    @user.headache_logs.destroy_all
    [ "2026-01-01 02:00", "2026-03-01 02:00" ].each do |start|
      @user.headache_logs.create!(start_time: Time.zone.parse(start), end_time: Time.zone.parse(start) + 1.hour, intensity: 7)
    end

    get charts_url

    remissions = JSON.parse(css_select("[data-controller=charts]").first["data-charts-remissions-value"])
    assert_equal [ { "from" => "2026-01-02", "to" => "2026-02-28", "days" => 58 } ], remissions
  end
end
