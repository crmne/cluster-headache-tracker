class Users::UsernamesController < ApplicationController
  before_action :authenticate_user!

  def update
    if current_user.update_with_password(username_params)
      bypass_sign_in(current_user)
      redirect_to settings_path, notice: "Username was successfully updated."
    else
      render "users/settings/show", status: :unprocessable_entity
    end
  end

  private

  def username_params
    params.require(:user).permit(:username, :current_password)
  end
end
