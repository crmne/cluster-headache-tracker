class Admin::Users::PasswordResetsController < Admin::BaseController
  def create
    user = User.find(params[:user_id])
    new_password = SecureRandom.alphanumeric(12)

    if user.update(password: new_password, password_confirmation: new_password)
      flash[:notice] = "Password reset for #{user.username}. New password: #{new_password}"
    else
      flash[:alert] = "Failed to reset password for #{user.username}"
    end

    redirect_to admin_users_path
  end
end
