require "test_helper"

class Users::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "deleting the account with the password deletes everything in it" do
    assert_difference -> { User.count } => -1, -> { HeadacheLog.count } => -@user.headache_logs.count do
      delete settings_account_url, params: { user: { current_password: "password123" } }
    end

    assert_redirected_to new_user_session_path
    assert_equal "Your account and all of its data have been deleted.", flash[:notice]
    assert_not User.exists?(@user.id)
    assert_empty MedicationDose.where(user_id: @user.id)
    assert_empty Medication.where(user_id: @user.id)

    get headache_logs_url
    assert_redirected_to new_user_session_path
  end

  test "a wrong password deletes nothing" do
    assert_no_difference -> { User.count } do
      delete settings_account_url, params: { user: { current_password: "wrong" } }
    end

    assert_response :unprocessable_entity
    assert_select "#delete_account [role=alert]", "That password isn't right, so nothing was deleted."
    assert_select "#delete_account input[aria-invalid=true]"
  end

  test "signed out people are asked to sign in" do
    sign_out @user

    delete settings_account_url, params: { user: { current_password: "password123" } }

    assert_redirected_to new_user_session_path
    assert User.exists?(@user.id)
  end
end
