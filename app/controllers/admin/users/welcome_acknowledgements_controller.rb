class Admin::Users::WelcomeAcknowledgementsController < Admin::BaseController
  def destroy
    user = User.find(params[:user_id])
    user.update(welcome_seen_at: nil)
    redirect_to admin_users_path, notice: "Welcome modal reset for #{user.username}. They will see it on next visit."
  end
end
