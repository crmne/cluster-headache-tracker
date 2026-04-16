class HeadacheLogExportsController < ApplicationController
  before_action :authenticate_user!

  def show
    send_data current_user.headache_logs.to_csv, filename: "headache_logs-#{Date.current}.csv"
  rescue StandardError => error
    Rails.logger.error "Error generating CSV: #{error.message}"
    redirect_to settings_path, alert: "Error generating CSV. Please try again or contact support."
  end
end
