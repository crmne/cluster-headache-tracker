class Users::WelcomeAcknowledgementsController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.touch(:welcome_seen_at)
    redirect_back fallback_location: headache_logs_path
  end
end
