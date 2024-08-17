require "test_helper"

class ChartsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @headache_log = headache_logs(:headache_log_one)
    sign_in @user
  end

  test "should get index" do
    get charts_index_url
    assert_response :success
  end
end
