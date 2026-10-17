# Hotwire Native navigation endpoint
class RecedeHistoricalLocationsController < ApplicationController
  allow_without_health_data_consent

  def show
    if helpers.native_app_with_tabs?
      render layout: false
    else
      redirect_to headache_logs_path
    end
  end
end
