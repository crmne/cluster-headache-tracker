require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "non-admins are turned away" do
    sign_in users(:one)
    get admin_users_url
    assert_redirected_to root_path
  end

  test "admins can destroy a user" do
    sign_in users(:carmine)
    assert_difference("User.count", -1) { delete admin_user_url(users(:one)) }
    assert_redirected_to admin_users_path
  end
end
