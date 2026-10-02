require "test_helper"

class HeadacheLogs::PhotosControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @headache_log = headache_logs(:one)
    @headache_log.photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")
    @photo = @headache_log.photos.first
  end

  test "shows the owner their photo" do
    sign_in users(:one)

    get headache_log_photo_url(@headache_log, @photo)

    assert_response :success
    assert_select "img[src=?]", headache_log_photo_variant_path(@headache_log, @photo, :large)
  end

  test "hides photos from other users" do
    sign_in users(:two)

    get headache_log_photo_url(@headache_log, @photo)

    assert_response :not_found
  end

  test "doesn't let other users remove photos" do
    sign_in users(:two)

    delete headache_log_photo_url(@headache_log, @photo)

    assert_response :not_found
    assert @headache_log.reload.photos.attached?
  end

  test "hides photos from signed out visitors" do
    get headache_log_photo_url(@headache_log, @photo)

    assert_redirected_to new_user_session_url
  end

  test "doesn't find a photo through another log" do
    sign_in users(:one)

    get headache_log_photo_url(headache_logs(:three), @photo)

    assert_response :not_found
  end

  test "removes a photo" do
    sign_in users(:one)

    perform_enqueued_jobs do
      delete headache_log_photo_url(@headache_log, @photo)
    end

    assert_redirected_to edit_headache_log_url(@headache_log)
    assert_not @headache_log.reload.photos.attached?
    assert_not ActiveStorage::Blob.exists?(@photo.blob_id)
  end
end
