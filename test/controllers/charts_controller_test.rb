require "test_helper"

class ChartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get charts_url
    assert_response :success
    assert_select "h2", "Headache Intensity Over Time"
  end

  test "should require authentication" do
    sign_out @user
    get charts_url
    assert_redirected_to new_user_session_path
  end

  test "should show charts with filtered data" do
    get charts_url, params: {
      start_time: Date.yesterday,
      end_time: Date.tomorrow,
      triggers: "Sleeping"
    }
    assert_response :success
  end

  test "shows how well each medication worked and preventive adherence" do
    get charts_url

    assert_select "#medication_insights" do
      assert_select "tr", text: /Oxygen.*100%/m
      assert_select "canvas#adherenceChart"
    end
    assert_select "[data-charts-medication-colors-value*=?]", "#0ea5e9"
  end
end
