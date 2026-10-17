# Asks people who signed up before the consent checkbox existed for their
# explicit consent to the processing of their health data, once.
class Users::HealthDataConsentsController < ApplicationController
  before_action :authenticate_user!
  allow_without_health_data_consent

  def show
    redirect_to headache_logs_path if current_user.consented?
  end

  def create
    if params[:health_data_consent] == "1"
      current_user.consent_to_health_data
      redirect_after_consent
    else
      @consent_missing = true
      render :show, status: :unprocessable_entity
    end
  end

  private
    def redirect_after_consent
      if helpers.native_app_with_tabs?
        # Rebuilds every tab, since each was sent here
        redirect_to "/recede_historical_location"
      else
        redirect_to stored_location_for(:user) || headache_logs_path
      end
    end
end
