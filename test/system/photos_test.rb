require "application_system_test_case"

class PhotosTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @user.update!(welcome_seen_at: Time.current, last_seen_changelog: ChangelogEntry.current.key)
    sign_in @user
  end

  test "attaching, viewing and removing photos" do
    visit new_headache_log_url

    attach_file "headache_log_photos", [ file_fixture("photo.jpg"), file_fixture("photo.heic") ], make_visible: true
    assert_selector "[data-photo-picker-target=previews] img[alt='photo.jpg']"

    click_button "Create Headache log"
    wait_until { @user.headache_logs.count == 3 }

    visit headache_logs_url
    click_on "2 photos"
    assert_selector "img[alt^='Photo 1 from the attack']"
    assert_photos_loaded

    find("img[alt^='Photo 2 from the attack']").click
    assert_selector "div.navbar-center", text: "Photo"
    assert_photos_loaded

    accept_confirm { click_button "Remove photo" }
    assert_text "Photo removed."
    assert_current_path edit_headache_log_path(@user.headache_logs.order(:created_at).last)
    assert_selector "img[alt^='Photo 1 from the attack']", count: 1
    assert_no_selector "img[alt^='Photo 2 from the attack']"
  end

  test "adding a photo to an existing log keeps the ones already there" do
    headache_log = headache_logs(:one)
    headache_log.photos.attach(io: file_fixture("photo.jpg").open, filename: "photo.jpg")

    visit edit_headache_log_url(headache_log)
    attach_file "headache_log_photos", file_fixture("photo.heic"), make_visible: true
    click_button "Update Headache log"

    wait_until { headache_log.reload.photos.count == 2 }
    assert_equal %w[ photo.heic photo.jpg ], headache_log.photos.map { |photo| photo.filename.to_s }.sort
  end

  private
    def wait_until(timeout: 10.seconds)
      Timeout.timeout(timeout) { sleep 0.05 until yield }
    end

    def assert_photos_loaded
      wait_until do
        page.evaluate_script("Array.from(document.querySelectorAll('img[alt^=Photo]')).every(image => image.complete && image.naturalWidth > 0)")
      end
    end
end
