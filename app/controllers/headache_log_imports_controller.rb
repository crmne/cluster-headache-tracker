class HeadacheLogImportsController < ApplicationController
  before_action :authenticate_user!

  def create
    if params[:file].present?
      result = HeadacheLog.import_csv(file: params[:file], user: current_user)
      redirect_to headache_logs_path, flash: { result.imported.positive? ? :notice : :alert => summary_of(result) }
    else
      redirect_to headache_logs_path, alert: "Please select a CSV file to import."
    end
  rescue CSV::MalformedCSVError
    redirect_to headache_logs_path, alert: "Invalid CSV file format."
  rescue StandardError => error
    Rails.logger.error "Error importing CSV: #{error.message}"
    redirect_to headache_logs_path, alert: "An error occurred while importing the CSV file."
  end

  private
    def summary_of(result)
      [
        t(".detected", source: t(result.format, scope: "headache_log_imports.formats")),
        t(".imported", count: result.imported),
        (t(".skipped_duplicates", count: result.duplicates) if result.duplicates.positive?),
        (t(".skipped_invalid", count: result.invalid) if result.invalid.positive?)
      ].compact.join(" ")
    end
end
