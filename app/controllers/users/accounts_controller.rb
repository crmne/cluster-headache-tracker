class Users::AccountsController < ApplicationController
  before_action :authenticate_user!

  # Deletes the account and everything in it: logs, photos, medications, doses,
  # share links and feedback. Asking for the password again keeps someone else
  # holding an unlocked phone from wiping a patient's history.
  def destroy
    if current_user.destroy_with_password(params.dig(:user, :current_password))
      sign_out current_user
      redirect_to new_user_session_path, notice: t(".deleted")
    else
      # Shown beside the delete button rather than with the username and password forms.
      current_user.errors.clear
      @account_deletion_failed = true
      render "users/settings/show", status: :unprocessable_entity
    end
  end
end
