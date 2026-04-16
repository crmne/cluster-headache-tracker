class HeadacheLogImportsController < ApplicationController
  before_action :authenticate_user!

  def create
    if params[:file].present?
      imported_logs = HeadacheLog.import_csv(file: params[:file], user: current_user)
      redirect_to headache_logs_path, notice: "Successfully imported #{imported_logs} headache logs."
    else
      redirect_to headache_logs_path, alert: "Please select a CSV file to import."
    end
  rescue CSV::MalformedCSVError
    redirect_to headache_logs_path, alert: "Invalid CSV file format."
  rescue StandardError => error
    Rails.logger.error "Error importing CSV: #{error.message}"
    redirect_to headache_logs_path, alert: "An error occurred while importing the CSV file."
  end
end
