require "test_helper"

class HeadacheLogImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "imports a Migraine Buddy export and says so" do
    assert_difference -> { @user.headache_logs.count }, 1 do
      post headache_log_import_url, params: { file: fixture_file_upload("migraine_buddy_sample.csv", "text/csv") }
    end

    assert_redirected_to headache_logs_url
    assert_equal "Detected a Migraine Buddy export. Imported 1 headache log.", flash[:notice]
  end

  test "reports rows skipped as unreadable" do
    post headache_log_import_url, params: { file: fixture_file_upload("migraine_buddy_mixed.csv", "text/csv") }

    assert_equal "Detected a Migraine Buddy export. Imported 4 headache logs. Skipped 3 rows that couldn't be read.", flash[:notice]
  end

  test "reports attacks skipped on a repeated import as an alert" do
    post headache_log_import_url, params: { file: fixture_file_upload("migraine_buddy_mixed.csv", "text/csv") }
    follow_redirect!

    assert_no_difference -> { @user.headache_logs.count } do
      post headache_log_import_url, params: { file: fixture_file_upload("migraine_buddy_mixed.csv", "text/csv") }
    end

    assert_nil flash[:notice]
    assert_equal "Detected a Migraine Buddy export. No new headache logs were imported. " \
      "Skipped 4 attacks that were already logged. Skipped 3 rows that couldn't be read.", flash[:alert]
  end

  test "reports a single skipped duplicate" do
    post headache_log_import_url, params: { file: fixture_file_upload("migraine_buddy_sample.csv", "text/csv") }
    follow_redirect!
    post headache_log_import_url, params: { file: fixture_file_upload("migraine_buddy_sample.csv", "text/csv") }

    assert_equal "Detected a Migraine Buddy export. No new headache logs were imported. Skipped 1 attack that was already logged.", flash[:alert]
  end

  test "asks for a file when none is given" do
    post headache_log_import_url

    assert_equal "Please select a CSV file to import.", flash[:alert]
  end
end
