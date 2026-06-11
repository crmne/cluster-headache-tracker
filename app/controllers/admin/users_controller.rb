class Admin::UsersController < Admin::BaseController
  def index
    @users = User.all

    if params[:search].present?
      @users = @users.where("username ILIKE ?", "%#{params[:search]}%")
    end

    @users = @users.order(created_at: :desc)
  end

  def destroy
    user = User.find(params[:id])
    username = user.username
    user.destroy
    redirect_to admin_users_path, notice: "User #{username} has been deleted."
  end
end
