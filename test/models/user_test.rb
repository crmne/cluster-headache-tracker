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
end
