class AdminNotificationsMailer < ApplicationMailer
  default from: "hello@clusterheadachetracker.com",
          to: "carmine@paolino.me"

  def new_user_notification(user)
    @user = user
    @total_users = User.count
    @total_headache_logs = HeadacheLog.count
    @average_logs_per_user = User.joins(:headache_logs).distinct.average("(SELECT COUNT(*) FROM headache_logs WHERE user_id = users.id)").to_f.round(1)
    @users_seen_changelog = User.where.not(last_seen_changelog: nil).count
    @changelog_percentage = (@total_users > 0 ? (@users_seen_changelog.to_f / @total_users * 100).round : 0)

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
