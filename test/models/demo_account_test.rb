require "test_helper"

class DemoAccountTest < ActiveSupport::TestCase
  test "creates a made-up patient whose history ends today" do
    account = DemoAccount.reset!(username: "appreview", password: "review-password-1")
    user = account.user

    assert user.valid_password?("review-password-1")
    assert_equal "en", user.locale
    assert user.welcome_seen_at
    assert_operator user.headache_logs.count, :>=, 15
    assert_equal [ "Oxygen", "Sumatriptan injection", "Verapamil" ], user.medications.order(:name).pluck(:name)
    assert user.headache_logs.all? { |log| log.end_time && log.start_time >= DemoAccount::PERIOD_DAYS.days.ago.beginning_of_day }
    assert user.headache_logs.where(start_time: 2.days.ago.beginning_of_day..).exists? || user.headache_logs.maximum(:start_time) > 7.days.ago
    assert_match "oxygen", user.headache_logs.first.medication
    assert user.medication_doses.where(medication: user.medications.find_by(name: "Verapamil")).count > 5
  end

  test "resetting replaces the history instead of adding to it" do
    DemoAccount.reset!(username: "appreview", password: "review-password-1")
    first_count = User.find_by(username: "appreview").headache_logs.count

    DemoAccount.reset!(username: "appreview", password: "review-password-2", ongoing_attack: true)
    user = User.find_by(username: "appreview")

    assert_equal first_count + 1, user.headache_logs.count
    assert user.current_attack
    assert user.valid_password?("review-password-2")
  end

  test "never resets a real person's account" do
    real = users(:one)
    real.headache_logs.create!(start_time: 1.day.ago, end_time: 1.day.ago + 30.minutes, intensity: 7, notes: "My own words")

    assert_raises(DemoAccount::NotADemoAccount) do
      DemoAccount.reset!(username: real.username, password: "whatever123")
    end
    assert real.reload.valid_password?("password123")
    assert real.headache_logs.exists?(notes: "My own words")
  end
end
