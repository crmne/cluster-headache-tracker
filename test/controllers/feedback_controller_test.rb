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

  test "the survey shows translated labels but submits the stored values" do
    @user.update!(locale: "de")

    get new_feedback_url

    assert_select "h1", "Helfen Sie uns, besser zu werden"
    assert_select "option[value='1-2 months']", "1–2 Monate"
    assert_select "input[type=checkbox][value='Identifying triggers'] + span", "Auslöser erkennen"
  end

  test "an incomplete survey lists what is missing in the user's language" do
    @user.update!(locale: "es")

    post feedback_url, params: { feedback_survey: { usage_duration: "" } }

    assert_response :unprocessable_entity
    assert_select ".alert-error", /Cuánto tiempo llevas usando el registro/
  end

  test "the thank you page is translated" do
    @user.update!(locale: "it")
    post feedback_url, params: { feedback_survey: survey_params }

    get thank_you_feedback_url

    assert_select "h1", "Grazie!"
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
