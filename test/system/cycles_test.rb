require "application_system_test_case"

class CyclesTest < ApplicationSystemTestCase
  setup do
    @user = users(:carmine)
    [ 60, 30, 28 ].each do |days_ago|
      started_at = (Date.current - days_ago).in_time_zone.change(hour: 12)
      @user.headache_logs.create!(start_time: started_at, end_time: started_at + 1.hour, intensity: 7)
    end

    sign_in @user
  end

  test "dashboard shows streaks and the charts page shows cycles" do
    visit headache_logs_url

    within "#attack_streaks" do
      assert_selector "#longest_streak .stat-value", text: "29 days"
      assert_selector "#attack_days .stat-value", text: "3"
      assert_selector "#attack_days .stat-desc", text: "in 2 cycles"
    end
    assert_predicate page.driver.browser.manage.cookie_named("time_zone")[:value], :present?

    visit charts_url

    within "#cycles" do
      assert_selector "h2", text: "Cycles"
      assert_selector "#cycle_count .stat-value", text: "2"
      assert_selector "#attack_calendar [data-attacks='1']", count: 3
      assert_selector "#cycles_table tbody tr", count: 2
      assert_selector "#cycles_table tbody tr:first-child td", text: "29 days"
    end
  end

  test "streaks update live when an attack is logged" do
    visit headache_logs_url
    assert_no_selector "#current_streak .stat-value", text: "Attack ongoing"

    @user.headache_logs.create!(start_time: Time.current, intensity: 6)

    assert_selector "#current_streak .stat-value", text: "Attack ongoing"
  end
end
