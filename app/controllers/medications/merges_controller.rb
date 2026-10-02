class Medications::MergesController < ApplicationController
  before_action :authenticate_user!

  def create
    medication = current_user.medications.find(params[:medication_id])
    target = current_user.medications.where.not(id: medication.id).find(params[:target_id])

    medication.merge_into(target)

    redirect_to medication_path(target), notice: t("medications.notices.merged", name: medication.name, target: target.name), status: :see_other
  end
end
