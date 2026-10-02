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
