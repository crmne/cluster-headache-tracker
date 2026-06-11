class Admin::WelcomeAcknowledgementsController < Admin::BaseController
  def destroy
    User.update_all(welcome_seen_at: nil)
    redirect_to admin_users_path, notice: "All users will see the welcome modal on their next visit."
  end
end
