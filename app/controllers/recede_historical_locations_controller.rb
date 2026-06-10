# Hotwire Native navigation endpoint
class RecedeHistoricalLocationsController < ApplicationController
  def show
    if helpers.native_app_with_tabs?
      render layout: false
    else
      redirect_to headache_logs_path
    end
  end
end
