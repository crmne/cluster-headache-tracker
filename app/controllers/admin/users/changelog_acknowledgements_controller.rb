class Admin::Users::ChangelogAcknowledgementsController < Admin::BaseController
  def destroy
    user = User.find(params[:user_id])
    user.update(last_seen_changelog: nil)
    redirect_to admin_users_path, notice: "Changelog reset for #{user.username}. They will see it on next visit."
  end
end
