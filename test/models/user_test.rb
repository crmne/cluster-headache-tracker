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
      token = @user.generate_share_token
      assert_not_nil token
      assert_not_nil token.token
      assert_not_nil token.expires_at
      assert_equal @user, token.user
    end
  end
end
