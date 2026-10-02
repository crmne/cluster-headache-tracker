class HeadacheLogImportsController < ApplicationController
  before_action :authenticate_user!

  def create
    if params[:file].blank?
      redirect_to headache_logs_path, alert: "Please select a CSV file to import."
    elsif MedicationDose.csv_file?(params[:file])
      imported_doses = MedicationDose.import_csv(file: params[:file], user: current_user)
      redirect_to headache_logs_path, notice: t("medication_doses.notices.imported", count: imported_doses)
    else
      imported_logs = HeadacheLog.import_csv(file: params[:file], user: current_user)
      redirect_to headache_logs_path, notice: "Successfully imported #{imported_logs} headache logs."
    end
  rescue CSV::MalformedCSVError
    redirect_to headache_logs_path, alert: "Invalid CSV file format."
  rescue StandardError => error
    Rails.logger.error "Error importing CSV: #{error.message}"
    redirect_to headache_logs_path, alert: "An error occurred while importing the CSV file."
  end
end
