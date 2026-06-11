class Users::WelcomeAcknowledgementsController < ApplicationController
  before_action :authenticate_user!

  def create
    if current_user.update(has_seen_welcome: true)
      head :ok
    else
      head :unprocessable_entity
    end
  end
end
