class MedicationDosesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_medication_dose, only: %i[ edit update destroy ]

  def new
    @medications = current_user.medications.active.by_recent_use
    @medication_dose = current_user.medication_doses.new(medication: @medications.find_by(id: params[:medication_id]))
  end

  def edit
  end

  def create
    @medication_dose = current_user.medication_doses.new(medication_dose_params)

    if @medication_dose.save
      redirect_back_or_to timeline_path, notice: t("medication_doses.notices.created", name: @medication_dose.medication.name), status: :see_other
    else
      @medications = current_user.medications.active.by_recent_use
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @medication_dose.update(medication_dose_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to timeline_path, notice: t("medication_doses.notices.updated", name: @medication_dose.medication.name), status: :see_other }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @medication_dose.destroy!

    redirect_to timeline_path, notice: t("medication_doses.notices.destroyed", name: @medication_dose.medication.name), status: :see_other
  end

  private
    def set_medication_dose
      @medication_dose = current_user.medication_doses.find(params[:id])
    end

    def medication_dose_params
      params.expect(medication_dose: [ :medication_id, :medication_name, :medication_kind, :taken_at, :amount, :unit, :duration_minutes, :effectiveness, :minutes_to_relief ])
    end
end
