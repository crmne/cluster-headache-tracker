require "test_helper"

class User::ReviewPromptingTest < ActiveSupport::TestCase
  setup do
    @user = users(:two)
    @user.update_column :headache_logs_count, User::ReviewPrompting::REVIEW_PROMPT_MINIMUM_LOGS
  end

  test "due once enough attacks are logged and the last one ended hours ago" do
    assert @user.review_prompt_due?
  end

  test "not due before the app has proven useful" do
    @user.update_column :headache_logs_count, User::ReviewPrompting::REVIEW_PROMPT_MINIMUM_LOGS - 1

    assert_not @user.review_prompt_due?
  end

  test "not due during an attack" do
    @user.headache_logs.create!(start_time: 10.minutes.ago, intensity: 8)

    assert_not @user.review_prompt_due?
  end

  test "not due right after an attack" do
    @user.headache_logs.create!(start_time: 2.hours.ago, end_time: 1.hour.ago, intensity: 8)

    assert_not @user.review_prompt_due?
  end

  test "not due again until the interval passes" do
    @user.review_prompted
    assert_not @user.review_prompt_due?

    travel User::ReviewPrompting::REVIEW_PROMPT_INTERVAL + 1.day do
      assert @user.review_prompt_due?
    end
  end
end
