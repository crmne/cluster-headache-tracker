require "test_helper"

class HeadacheLogsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @headache_log = headache_logs(:headache_log_one)
    sign_in @user
  end

  test "should get index" do
    get headache_logs_url
    assert_response :success
  end

  test "should get new" do
    get new_headache_log_url
    assert_response :success
  end

  test "should create headache_log" do
    assert_difference("HeadacheLog.count") do
      post headache_logs_url, params: { headache_log: { end_time: @headache_log.end_time, intensity: @headache_log.intensity, notes: @headache_log.notes, start_time: @headache_log.start_time, user_id: @headache_log.user_id } }
    end

    assert_redirected_to headache_log_url(HeadacheLog.last)
  end

  test "should show headache_log" do
    get headache_log_url(@headache_log)
    assert_response :success
  end

  test "should get edit" do
    get edit_headache_log_url(@headache_log)
    assert_response :success
  end

  test "should update headache_log" do
    patch headache_log_url(@headache_log), params: { headache_log: { end_time: @headache_log.end_time, intensity: @headache_log.intensity, notes: @headache_log.notes, start_time: @headache_log.start_time, user_id: @headache_log.user_id } }
    assert_redirected_to headache_log_url(@headache_log)
  end

  test "should destroy headache_log" do
    assert_difference("HeadacheLog.count", -1) do
      delete headache_log_url(@headache_log)
    end

    assert_redirected_to headache_logs_url
  end
end
