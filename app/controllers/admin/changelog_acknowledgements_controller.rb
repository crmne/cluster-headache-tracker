class Admin::ChangelogAcknowledgementsController < Admin::BaseController
  def destroy
    User.update_all(last_seen_changelog: nil)
    redirect_to admin_users_path, notice: "All users will see the changelog on their next visit."
  end
end
