class HeadacheLogImportsController < ApplicationController
  before_action :authenticate_user!

  def create
    if params[:file].present?
      imported_logs = HeadacheLog.import_csv(file: params[:file], user: current_user)
      redirect_to headache_logs_path, notice: t(".imported", count: imported_logs)
    else
      redirect_to headache_logs_path, alert: t(".missing_file")
    end
  rescue CSV::MalformedCSVError
    redirect_to headache_logs_path, alert: t(".invalid_file")
  rescue StandardError => error
    Rails.logger.error "Error importing CSV: #{error.message}"
    redirect_to headache_logs_path, alert: t(".failed")
  end
end
