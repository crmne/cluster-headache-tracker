require "test_helper"

class HeadacheLogs::Photos::VariantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @headache_log = headache_logs(:one)
    @headache_log.photos.attach(io: file_fixture("photo.heic").open, filename: "photo.heic")
    @photo = @headache_log.photos.first
  end

  test "serves the owner a JPEG they can display, uncached" do
    sign_in users(:one)

    get headache_log_photo_variant_url(@headache_log, @photo, :thumb)

    assert_response :success
    assert_equal "image/jpeg", response.media_type
    assert_equal "\xFF\xD8\xFF".b, response.body.byteslice(0, 3)
    assert_match "inline", response.headers["Content-Disposition"]
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "serves the large variant" do
    sign_in users(:one)

    get headache_log_photo_variant_url(@headache_log, @photo, :large)

    assert_response :success
    assert_equal "image/jpeg", response.media_type
  end

  test "hides photos from other users" do
    sign_in users(:two)

    get headache_log_photo_variant_url(@headache_log, @photo, :thumb)

    assert_response :not_found
  end

  test "hides photos from signed out visitors" do
    get headache_log_photo_variant_url(@headache_log, @photo, :thumb)

    assert_redirected_to new_user_session_url
  end

  test "only serves known variants" do
    sign_in users(:one)

    get "/headache_logs/#{@headache_log.id}/photos/#{@photo.id}/variants/original"

    assert_response :not_found
  end
end
