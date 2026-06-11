class Admin::Users::WelcomeAcknowledgementsController < Admin::BaseController
  def destroy
    user = User.find(params[:user_id])
    user.update(has_seen_welcome: false)
    redirect_to admin_users_path, notice: "Welcome modal reset for #{user.username}. They will see it on next visit."
  end
end
