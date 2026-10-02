class HeadacheLogImportsController < ApplicationController
  before_action :authenticate_user!

  def create
    if params[:file].blank?
      redirect_to headache_logs_path, alert: t(".missing_file")
    elsif MedicationDose.csv_file?(params[:file])
      imported_doses = MedicationDose.import_csv(file: params[:file], user: current_user)
      redirect_to headache_logs_path, notice: t("medication_doses.notices.imported", count: imported_doses)
    else
      result = HeadacheLog.import_csv(file: params[:file], user: current_user)
      redirect_to headache_logs_path, flash: { result.imported.positive? ? :notice : :alert => summary_of(result) }
    end
  rescue CSV::MalformedCSVError
    redirect_to headache_logs_path, alert: t(".invalid_file")
  rescue StandardError => error
    Rails.logger.error "Error importing CSV: #{error.message}"
    redirect_to headache_logs_path, alert: t(".failed")
  end

  private
    def summary_of(result)
      [
        t("headache_log_imports.create.detected", source: t(result.format, scope: "headache_log_imports.formats")),
        t("headache_log_imports.create.imported", count: result.imported),
        (t("headache_log_imports.create.skipped_duplicates", count: result.duplicates) if result.duplicates.positive?),
        (t("headache_log_imports.create.skipped_invalid", count: result.invalid) if result.invalid.positive?)
      ].compact.join(" ")
    end
end
