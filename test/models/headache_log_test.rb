require "test_helper"

class HeadacheLogTest < ActiveSupport::TestCase
  test "should process attacks per day data correctly" do
    user = users(:one)

    # Clear existing headache logs
    HeadacheLog.destroy_all

    # Create multiple headache logs for testing
    HeadacheLog.create!(user: user, start_time: Date.today, intensity: 5)
    HeadacheLog.create!(user: user, start_time: Date.today, intensity: 6)
    HeadacheLog.create!(user: user, start_time: Date.today - 1.day, intensity: 7)

    headache_logs = user.headache_logs
    # puts "All headache logs: #{headache_logs.to_a.inspect}"

    attacks_per_day_data = HeadacheLog.process_attacks_per_day_data(headache_logs)

    # puts "Attacks per day data: #{attacks_per_day_data.inspect}"

    assert_equal 2, attacks_per_day_data.size
    assert_equal 2, attacks_per_day_data.find { |d| d[:x] == Date.today }[:y]
    assert_equal 1, attacks_per_day_data.find { |d| d[:x] == Date.today - 1.day }[:y]
  end
end
