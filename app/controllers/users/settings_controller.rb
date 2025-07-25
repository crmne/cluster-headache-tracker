class Users::SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def show
  end

  def update_username
    if @user.update_with_password(username_params)
      bypass_sign_in(@user)
      redirect_to settings_path, notice: "Username was successfully updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_password
    if @user.update_with_password(password_params)
      bypass_sign_in(@user)
      redirect_to settings_path, notice: "Password was successfully updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def changelog_acknowledged
    version = params[:version]
    if version.present? && current_user.update(last_seen_changelog: version)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def username_params
    params.require(:user).permit(:username, :current_password)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation, :current_password)
  end
end
