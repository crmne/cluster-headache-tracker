class Users::WelcomeAcknowledgementsController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.touch(:welcome_seen_at)
    head :ok
  end
end
