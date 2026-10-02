class CurrentAttacksController < ApplicationController
  before_action :authenticate_user!

  def show
    respond_to do |format|
      format.html { @current_attack = current_user.current_attack }
      format.json { render json: current_user.widget_status }
    end
  end

  def create
    if current_user.start_attack(intensity: params[:intensity]).persisted?
      redirect_to current_attack_url, status: :see_other
    else
      redirect_to current_attack_url, alert: t(".invalid_intensity"), status: :see_other
    end
  end

  def destroy
    if current_user.end_current_attack
      redirect_back_or_to current_attack_url, notice: t(".ended"), status: :see_other
    else
      redirect_to current_attack_url, alert: t(".nothing_ongoing"), status: :see_other
    end
  end
end
