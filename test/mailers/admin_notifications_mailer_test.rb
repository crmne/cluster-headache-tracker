require "test_helper"

class AdminNotificationsMailerTest < ActionMailer::TestCase
  test "new user notification reports the username and platform stats" do
    mail = AdminNotificationsMailer.new_user_notification(users(:one))

    assert_equal "New User Registration: testuser1", mail.subject
    assert_equal [ "carmine@paolino.me" ], mail.to
    assert_match "testuser1", mail.body.encoded
    assert_match "Total Users", mail.body.encoded
  end

  test "new feedback notification reports the survey answers" do
    survey = users(:carmine).create_feedback_survey!(
      usage_duration: "1-2 months",
      ease_of_use: 4,
      recommendation_likelihood: 5,
      versions: [ "Web" ],
      most_useful_features: [ "Identifying triggers" ]
    )

    mail = AdminNotificationsMailer.new_feedback_notification(survey)

    assert_equal "New Feedback from carmine", mail.subject
    assert_equal [ "carmine@paolino.me" ], mail.to
    assert_match "Identifying triggers", mail.body.encoded
  end
end
