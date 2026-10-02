require "test_helper"

class CyclesHelperTest < ActionView::TestCase
  setup do
    @user = users(:carmine)
  end

  test "attack calendar covers the last year in whole weeks ending today" do
    weeks = attack_calendar_weeks(cycles(today: Date.new(2026, 10, 2)))
    days = weeks.flatten.compact

    assert weeks.all? { |week| week.size == 7 }
    assert_equal Date.new(2026, 10, 2), days.last
    assert_equal Date.new(2025, 10, 3).beginning_of_week, days.first
    assert_nil weeks.last.last, "days after today stay blank"
  end

  test "attack calendar of older logs ends at the last attack" do
    @user.headache_logs.create!(start_time: Time.zone.parse("2023-05-10 02:00"), end_time: Time.zone.parse("2023-05-10 03:00"), intensity: 6)

    days = attack_calendar_weeks(cycles(today: Date.new(2026, 10, 2))).flatten.compact

    assert_equal Date.new(2023, 5, 10), days.last
  end

  test "attack calendar levels" do
    assert_equal "bg-base-300", attack_calendar_cell_class(0)
    assert_equal "bg-error/30", attack_calendar_cell_class(1)
    assert_equal "bg-error/50", attack_calendar_cell_class(2)
    assert_equal "bg-error/75", attack_calendar_cell_class(4)
    assert_equal "bg-error", attack_calendar_cell_class(8)
  end

  test "attack calendar month labels mark the week a month starts" do
    assert_equal "Oct", attack_calendar_month_label((Date.new(2026, 9, 28)..Date.new(2026, 10, 4)).to_a)
    assert_nil attack_calendar_month_label((Date.new(2026, 10, 5)..Date.new(2026, 10, 11)).to_a)
  end

  test "days count" do
    assert_equal "1 day", days_count(1)
    assert_equal "12 days", days_count(12.0)
    assert_equal "12.5 days", days_count(12.5)
    assert_equal "—", days_count(nil)
  end

  private
    def cycles(today:)
      @user.headache_logs.cycles(today: today)
    end
end
