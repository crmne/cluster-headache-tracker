class MedicationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_medication, only: %i[ show edit update destroy ]

  def index
    @medications = current_user.medications.active.by_recent_use
    @archived_medications = current_user.medications.archived.alphabetically
  end

  def show
    @doses = @medication.doses.recent_first.includes(:headache_log).limit(100)
    @insights = Medication::Insights.new(user: current_user, headache_logs: current_user.headache_logs, from: @medication.created_at.to_date)
    @summary = @insights.summaries.find { |summary| summary.medication == @medication }
  end

  def new
    @medication = current_user.medications.new(kind: params[:kind].presence_in(Medication::KINDS) || "abortive")
  end

  def edit
  end

  def create
    @medication = current_user.medications.new(medication_params)

    if @medication.save
      redirect_to medications_path, notice: t("medications.notices.created", name: @medication.name), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @medication.update(medication_params)
      redirect_to medication_path(@medication), notice: t("medications.notices.updated", name: @medication.name), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @medication.destroy!

    redirect_to medications_path, notice: t("medications.notices.destroyed", name: @medication.name), status: :see_other
  end

  private
    def set_medication
      @medication = current_user.medications.find(params[:id])
    end

    def medication_params
      params.expect(medication: [ :name, :kind, :default_dose, :unit, :frequency, :schedule_note, :color, :archived ])
    end
end
