class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :destroy, :reset_password, :reset_changelog, :reset_welcome ]

  def index
    @users = User.includes(:headache_logs)

    if params[:search].present?
      @users = @users.where("username ILIKE ?", "%#{params[:search]}%")
    end

    @users = @users.order(created_at: :desc)
  end

  def destroy
    username = @user.username
    @user.destroy
    redirect_to admin_users_path, notice: "User #{username} has been deleted."
  end

  def reset_password
    new_password = SecureRandom.alphanumeric(12)

    if @user.update(password: new_password, password_confirmation: new_password)
      flash[:notice] = "Password reset for #{@user.username}. New password: #{new_password}"
    else
      flash[:alert] = "Failed to reset password for #{@user.username}"
    end

    redirect_to admin_users_path
  end

  def reset_changelog
    @user.update(last_seen_changelog: nil)
    redirect_to admin_users_path, notice: "Changelog reset for #{@user.username}. They will see it on next visit."
  end

  def reset_all_changelogs
    User.update_all(last_seen_changelog: nil)
    redirect_to admin_users_path, notice: "All users will see the changelog on their next visit."
  end

  def reset_welcome
    @user.update(has_seen_welcome: false)
    redirect_to admin_users_path, notice: "Welcome modal reset for #{@user.username}. They will see it on next visit."
  end

  def reset_all_welcomes
    User.update_all(has_seen_welcome: false)
    redirect_to admin_users_path, notice: "All users will see the welcome modal on their next visit."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
