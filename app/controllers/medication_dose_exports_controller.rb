class MedicationDoseExportsController < ApplicationController
  before_action :authenticate_user!
  allow_without_health_data_consent

  def show
    send_data current_user.medication_doses.to_csv, filename: "medication_doses-#{Date.current}.csv"
  end
end
