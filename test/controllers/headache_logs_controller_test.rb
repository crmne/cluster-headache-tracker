require "test_helper"

class HeadacheLogsControllerTest < ActionDispatch::IntegrationTest
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

  test "should not find another user's headache log" do
    get edit_headache_log_url(headache_logs(:two))
    assert_response :not_found
  end

  test "should show ongoing headaches alert" do
    @headache_log.update(end_time: nil)
    get headache_logs_url
    assert_select ".alert", /Ongoing Headache/i
  end

  test "should generate share link" do
    assert_difference("ShareToken.count") do
      post share_link_url
    end
    assert_redirected_to headache_logs_url
    assert_equal "Share link generated successfully.", flash[:notice]
  end

  test "should expire share link" do
    ShareToken.destroy_all
    @user.share_tokens.create!
    assert_difference("ShareToken.count", -1) do
      delete share_link_url
    end
    assert_redirected_to headache_logs_url
    assert_equal "Share link has been expired.", flash[:notice]
  end

  test "should export logs to CSV" do
    get headache_log_export_url(format: :csv)
    assert_response :success
    assert_equal "text/csv", @response.content_type
    assert_match /start_time,end_time,intensity,medication,triggers,notes/, response.body
  end

  test "should import logs from CSV" do
    file = fixture_file_upload("test/fixtures/files/sample_logs.csv", "text/csv")
    assert_difference("HeadacheLog.count", 3) do
      post headache_log_import_url, params: { file: file }
    end
    assert_redirected_to headache_logs_url
    assert_match /Successfully imported/, flash[:notice]

    log = @user.headache_logs.find_by!(notes: "Morning attack")
    assert_equal Time.zone.parse("2024-03-01 08:00:00"), log.start_time
    assert_equal Time.zone.parse("2024-03-01 10:30:00"), log.end_time
    assert_equal 7, log.intensity
    assert_equal "sumatriptan", log.medication
    assert_equal "Lack of sleep", log.triggers
  end

  test "should round-trip logs through export and import unchanged" do
    @user.headache_logs.destroy_all
    @user.headache_logs.create!(
      start_time: Time.zone.parse("2024-03-01 08:00:00"),
      end_time: Time.zone.parse("2024-03-01 10:30:00"),
      intensity: 7,
      medication: "Sumatriptan",
      triggers: "Lack of sleep",
      notes: "Morning attack"
    )
    @user.headache_logs.create!(
      start_time: Time.zone.parse("2024-03-02 23:00:00"),
      intensity: 9,
      medication: "Oxygen, Verapamil",
      triggers: "Alcohol"
    )

    get headache_log_export_url(format: :csv)
    exported_csv = response.body

    @user.headache_logs.destroy_all
    Tempfile.create([ "exported_logs", ".csv" ]) do |file|
      file.write(exported_csv)
      file.rewind

      assert_difference("HeadacheLog.count", 2) do
        post headache_log_import_url, params: { file: Rack::Test::UploadedFile.new(file.path, "text/csv") }
      end
    end

    get headache_log_export_url(format: :csv)
    assert_equal exported_csv, response.body
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

  test "should create a log with photos" do
    assert_difference -> { ActiveStorage::Attachment.count }, 2 do
      post headache_logs_url, params: { headache_log: {
        start_time: Time.current, intensity: 6,
        photos: [ fixture_file_upload("photo.jpg", "image/jpeg"), fixture_file_upload("photo.heic", "image/heic") ]
      } }
    end

    assert_redirected_to headache_logs_url
    assert_equal 2, @user.headache_logs.order(:created_at).last.photos.count
  end

  test "should keep stored photos when adding more" do
    @headache_log.photos.attach(io: file_fixture("photo.jpg").open, filename: "kept.jpg")

    patch headache_log_url(@headache_log), params: { headache_log: {
      photos: [ @headache_log.photos.first.signed_id, fixture_file_upload("photo.heic", "image/heic") ]
    } }

    assert_redirected_to headache_logs_url
    assert_equal %w[ kept.jpg photo.heic ], @headache_log.photos.reload.map { |photo| photo.filename.to_s }.sort
  end

  test "should reject a sixth photo" do
    5.times { @headache_log.photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg") }

    patch headache_log_url(@headache_log), params: { headache_log: {
      photos: @headache_log.photos.map(&:signed_id) + [ fixture_file_upload("photo.jpg", "image/jpeg") ]
    } }

    assert_response :unprocessable_entity
    assert_select ".alert-error", /Photos can't be more than 5 per attack/
    assert_equal 5, @headache_log.photos.reload.count
  end

  test "should show the log's photos" do
    @headache_log.photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")

    get headache_log_url(@headache_log)

    assert_select "img[src=?]", headache_log_photo_variant_path(@headache_log, @headache_log.photos.first, :thumb)
  end

  test "should include photos in the print report" do
    @headache_log.photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")

    get headache_log_print_url

    assert_response :success
    assert_select "img[src=?]", headache_log_photo_variant_path(@headache_log, @headache_log.photos.first, :large)
  end
end
