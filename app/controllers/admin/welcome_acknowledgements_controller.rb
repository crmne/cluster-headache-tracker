class Admin::WelcomeAcknowledgementsController < Admin::BaseController
  def destroy
    User.update_all(has_seen_welcome: false)
    redirect_to admin_users_path, notice: "All users will see the welcome modal on their next visit."
  end
end
