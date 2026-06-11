class AdminNotificationsMailer < ApplicationMailer
  default from: "hello@clusterheadachetracker.com",
          to: "carmine@paolino.me"

  def new_user_notification(user)
    @user = user
    @stats = User.signup_stats

    mail(subject: "New User Registration: #{@user.username}")
  end

  def new_feedback_notification(feedback_survey)
    @feedback_survey = feedback_survey
    @total_feedback = FeedbackSurvey.count
    @average_ease_rating = FeedbackSurvey.average(:ease_of_use)&.round(1)
    @average_recommendation = FeedbackSurvey.average(:recommendation_likelihood)&.round(1)

    mail(subject: "New Feedback from #{@feedback_survey.user.username}")
  end
end
