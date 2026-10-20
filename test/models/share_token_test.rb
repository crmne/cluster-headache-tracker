require "test_helper"

class ShareTokenTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @share_token = ShareToken.new(user: @user)
  end

  test "should be valid" do
    assert @share_token.valid?
  end

  test "should belong to user" do
    @share_token.user = nil
    assert_not @share_token.valid?
  end

  test "should generate token" do
    @share_token.save
    assert_not_nil @share_token.token
  end

  test "should set expiration date before create" do
    assert_nil @share_token.expires_at
    @share_token.save
    assert_not_nil @share_token.expires_at
    assert_equal 30.days.from_now.to_date, @share_token.expires_at.to_date
  end

  test "is paused while its owner hasn't consented to health data processing" do
    assert_not share_tokens(:one).paused?

    users(:one).update!(consented_at: nil)
    assert share_tokens(:one).reload.paused?
  end
end
