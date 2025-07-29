class FeedbackController < ApplicationController
  before_action :authenticate_user!
  before_action :check_existing_survey, only: [ :show, :new, :create ]

  def show
    redirect_to new_feedback_path
  end

  def new
    @feedback_survey = current_user.build_feedback_survey
  end

  def create
    @feedback_survey = current_user.build_feedback_survey(feedback_survey_params)
    @feedback_survey.user_agent = request.user_agent

    if @feedback_survey.save
      AdminNotificationsMailer.new_feedback_notification(@feedback_survey).deliver_later
      redirect_to thank_you_feedback_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def thank_you
  end

  private

  def feedback_survey_params
    params.require(:feedback_survey).permit(
      :usage_duration,
      :ease_of_use,
      :shared_with_doctor,
      :impact,
      :change_suggestion,
      :recommendation_likelihood,
      :promotion_suggestions,
      :additional_features,
      :mobile_interest,
      versions: [],
      most_useful_features: []
    )
  end

  def check_existing_survey
    if current_user.feedback_survey.present?
      redirect_to thank_you_feedback_path, notice: "You've already submitted your feedback. Thank you!"
    end
  end
end
