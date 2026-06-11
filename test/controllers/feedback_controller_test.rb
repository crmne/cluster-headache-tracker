require "test_helper"

class FeedbackControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @user.feedback_survey&.destroy
    @user.reload
    sign_in @user
  end

  test "creating feedback notifies the admins" do
    assert_difference("FeedbackSurvey.count") do
      assert_enqueued_emails 1 do
        post feedback_url, params: { feedback_survey: survey_params }
      end
    end

    assert_redirected_to thank_you_feedback_path
  end

  test "a second submission is redirected to the thank you page" do
    post feedback_url, params: { feedback_survey: survey_params }

    assert_no_difference("FeedbackSurvey.count") do
      post feedback_url, params: { feedback_survey: survey_params }
    end

    assert_redirected_to thank_you_feedback_path
  end

  test "destroying feedback allows resubmission" do
    post feedback_url, params: { feedback_survey: survey_params }

    assert_difference("FeedbackSurvey.count", -1) do
      delete feedback_url
    end
    assert_redirected_to new_feedback_path

    get new_feedback_url
    assert_response :success
  end

  private
    def survey_params
      {
        usage_duration: "1-2 months",
        ease_of_use: 4,
        recommendation_likelihood: 5,
        shared_with_doctor: true,
        versions: [ "Web" ],
        most_useful_features: [ "Identifying triggers" ]
      }
    end
end
