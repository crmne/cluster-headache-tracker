class Users::SettingsController < ApplicationController
  before_action :authenticate_user!
  allow_without_health_data_consent

  def show
  end
end
