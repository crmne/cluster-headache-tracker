class Admin::FeedbackSurveysController < Admin::BaseController
  def index
    @feedback_surveys = FeedbackSurvey.includes(:user).order(created_at: :desc)
    @stats = {
      total_responses: @feedback_surveys.count,
      average_ease: @feedback_surveys.average(:ease_of_use)&.round(2),
      average_recommendation: @feedback_surveys.average(:recommendation_likelihood)&.round(2),
      shared_with_doctor: @feedback_surveys.where(shared_with_doctor: true).count,
      platforms: @feedback_surveys.map(&:versions).flatten.tally,
      features: @feedback_surveys.map(&:most_useful_features).flatten.tally
    }
  end

  def show
    @feedback_survey = FeedbackSurvey.find(params[:id])
  end

  def import
    if params[:file].present?
      result = FeedbackSurvey.import_tally_csv(params[:file])
      message = "Import complete: #{result[:imported]} imported"
      message += ", #{result[:skipped_existing]} skipped (already have feedback)" if result[:skipped_existing] > 0
      message += ", #{result[:failed]} failed" if result[:failed] > 0

      redirect_to admin_feedback_surveys_path, notice: message
    else
      redirect_to admin_feedback_surveys_path, alert: "Please select a CSV file to import"
    end
  rescue CSV::MalformedCSVError => e
    Rails.logger.error "CSV Import Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to admin_feedback_surveys_path, alert: "CSV format error: #{e.message}. Make sure you're uploading a valid Tally CSV export."
  rescue => e
    Rails.logger.error "Import Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to admin_feedback_surveys_path, alert: "Import failed: #{e.message}"
  end

  def destroy
    @feedback_survey = FeedbackSurvey.find(params[:id])
    username = @feedback_survey.user.username
    @feedback_survey.destroy
    redirect_to admin_feedback_surveys_path, notice: "Feedback from #{username} has been reset"
  end

  def destroy_all
    count = FeedbackSurvey.count
    FeedbackSurvey.destroy_all
    redirect_to admin_feedback_surveys_path, notice: "All #{count} feedback entries have been reset"
  end
end
