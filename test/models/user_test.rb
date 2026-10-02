require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(username: "testuser", password: "password123")
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "username should be present" do
    @user.username = "     "
    assert_not @user.valid?
  end

  test "username should be unique" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
  end

  test "should generate share token" do
    @user.save
    assert_difference "ShareToken.count" do
      token = @user.share_tokens.create!
      assert_not_nil token
      assert_not_nil token.token
      assert_not_nil token.expires_at
      assert_equal @user, token.user
    end
  end

  test "should return current share token" do
    @user.save
    expired_token = @user.share_tokens.create!
    expired_token.update!(expires_at: 1.day.ago)

    current_token = @user.share_tokens.create!

    assert_equal current_token, @user.current_share_token
  end

  test "widget status without any attacks" do
    @user.save!

    assert_equal({
      ongoing: false,
      startedAt: nil,
      lastAttackAt: nil,
      attackFreeDays: 0,
      attacksToday: 0,
      locale: "en"
    }, @user.widget_status)
  end

  test "widget status counts attack-free days since the last attack ended" do
    travel_to Time.zone.parse("2026-10-02 12:00")
    @user.save!
    last_attack = @user.headache_logs.create!(start_time: 3.days.ago, end_time: 3.days.ago + 1.hour, intensity: 7)

    status = @user.widget_status

    assert_not status[:ongoing]
    assert_equal last_attack.start_time.iso8601, status[:lastAttackAt]
    assert_equal 3, status[:attackFreeDays]
    assert_equal 0, status[:attacksToday]
  end

  test "widget status reports the ongoing attack" do
    @user.save!
    attack = @user.start_attack(intensity: 9)

    status = @user.widget_status

    assert status[:ongoing]
    assert_equal attack.start_time.iso8601, status[:startedAt]
    assert_equal 0, status[:attackFreeDays]
    assert_equal 1, status[:attacksToday]
  end

  test "widget status reinterprets stored wall-clock times in the patient's time zone" do
    @user.save!
    @user.headache_logs.create!(start_time: Time.utc(2026, 10, 3, 1, 0), intensity: 8)
    berlin = ActiveSupport::TimeZone["Europe/Berlin"]

    travel_to Time.utc(2026, 10, 2, 23, 30) do
      status = @user.widget_status(time_zone: berlin)

      assert_equal "2026-10-03T01:00:00+02:00", status[:startedAt]
      assert_equal "2026-10-03T01:00:00+02:00", status[:lastAttackAt]
      assert_equal 1, status[:attacksToday]
    end
  end

  test "widget status falls back to the app time zone until the browser reports one" do
    @user.save!
    @user.headache_logs.create!(start_time: Time.utc(2026, 10, 2, 11, 44), intensity: 8)

    assert_equal "2026-10-02T11:44:00Z", @user.widget_status[:startedAt]

    Current.time_zone = ActiveSupport::TimeZone["America/New_York"]
    assert_equal "2026-10-02T11:44:00-04:00", @user.widget_status[:startedAt]
  end

  test "widget status uses the current locale" do
    @user.save!

    I18n.with_locale(:de) do
      assert_equal "de", @user.widget_status[:locale]
    end
  end

  test "end current attack ends only the most recent ongoing attack" do
    @user.save!
    attack = @user.start_attack(intensity: 6)

    assert_equal attack, @user.end_current_attack
    assert_not_nil attack.reload.end_time
    assert_nil @user.current_attack
    assert_nil @user.end_current_attack
  end

  test "locale must be an available language" do
    @user.locale = "de"
    assert @user.valid?

    @user.locale = "fr"
    assert_not @user.valid?
  end

  test "time format must be 12h or 24h" do
    @user.time_format = "24h"
    assert @user.valid?

    @user.time_format = "25h"
    assert_not @user.valid?
  end

  test "blank preferences mean automatic" do
    @user.locale = ""
    @user.time_format = ""

    assert_nil @user.locale
    assert_nil @user.time_format
  end

  test "the time format defaults to the convention of the language" do
    assert_equal "12h", @user.time_format_or_default

    @user.locale = "de"
    assert_equal "24h", @user.time_format_or_default

    @user.time_format = "12h"
    assert_equal "12h", @user.time_format_or_default
  end

  test "without a saved language the time format follows the current language" do
    I18n.with_locale(:it) { assert_equal "24h", @user.time_format_or_default }
  end
end
