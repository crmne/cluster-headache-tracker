require "test_helper"

class HeadacheLogsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @headache_log = headache_logs(:one)
    sign_in @user
  end

  test "should get index" do
    get headache_logs_url
    assert_response :success
    assert_select "title", /Headache Logs/  # Changed from h1 to title
    assert_select ".navbar", /Headache Logs/  # Check navbar title instead
  end

  test "should show ongoing headaches alert" do
    @headache_log.update(end_time: nil)
    get headache_logs_url
    assert_select ".alert", /Ongoing Headache/i
  end

  test "should generate share link" do
    assert_difference("ShareToken.count") do
      post generate_share_link_url
    end
    assert_redirected_to headache_logs_url
    assert_equal "Share link generated successfully.", flash[:notice]
  end

  test "should expire share link" do
    ShareToken.destroy_all  # Clear any existing tokens
    @user.generate_share_token
    assert_difference("ShareToken.count", -1) do
      delete expire_share_link_url
    end
    assert_redirected_to headache_logs_url
    assert_equal "Share link has been expired.", flash[:notice]
  end

  test "should export logs to CSV" do
    get export_headache_logs_url(format: :csv)
    assert_response :success
    assert_equal "text/csv", @response.content_type
    assert_match /start_time,end_time,intensity,medication,triggers,notes/, response.body
  end

  test "should import logs from CSV" do
    file = fixture_file_upload("test/fixtures/files/sample_logs.csv", "text/csv")
    assert_difference("HeadacheLog.count", 3) do  # Changed from 1 to 3
      post import_headache_logs_url, params: { file: file }
    end
    assert_redirected_to headache_logs_url
    assert_match /Successfully imported/, flash[:notice]
  end

  test "should filter logs by date range" do
    get headache_logs_url, params: {
      start_time: Date.yesterday,
      end_time: Date.tomorrow
    }
    assert_response :success
  end

  test "should filter logs by triggers" do
    get headache_logs_url, params: { triggers: "Sleeping" }
    assert_response :success
  end

  test "should filter logs by medication" do
    get headache_logs_url, params: { medication: "Sumatriptan" }
    assert_response :success
  end
end
