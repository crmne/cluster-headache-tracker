require "test_helper"

class HeadacheLog::PhotographedTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @headache_log = headache_logs(:one)
  end

  test "accepts JPEG, PNG, HEIC and WebP photos" do
    @headache_log.photos.attach(photo("photo.jpg"), photo("photo.heic"))

    assert @headache_log.valid?
    assert_equal %w[ image/heic image/jpeg ], @headache_log.photos.map(&:content_type).sort
  end

  test "allows at most five photos" do
    @headache_log.photos = Array.new(5) { photo("photo.jpg") }
    assert @headache_log.valid?

    @headache_log.photos = Array.new(6) { photo("photo.jpg") }
    assert_not @headache_log.valid?
    assert_includes @headache_log.errors.full_messages, "Photos can't be more than 5 per attack"
  end

  test "rejects files that aren't supported images" do
    @headache_log.photos = [ photo("not_a_photo.gif") ]

    assert_not @headache_log.valid?
    assert_includes @headache_log.errors.full_messages.to_sentence, "not_a_photo.gif isn't"
  end

  test "rejects photos larger than 10 MB" do
    @headache_log.photos = [ { io: StringIO.new("a" * (10.megabytes + 1)), filename: "huge.jpg", content_type: "image/jpeg", identify: false } ]

    assert_not @headache_log.valid?
    assert_includes @headache_log.errors.full_messages.to_sentence, "huge.jpg is too large"
  end

  test "converts photos to stripped JPEG variants for display" do
    @headache_log.photos.attach(photo("photo.heic"))

    variant = @headache_log.photos.first.variant(:thumb).processed

    assert_equal "image/jpeg", variant.variation.content_type
    assert_equal "\xFF\xD8\xFF".b, variant.download.byteslice(0, 3)
  end

  test "remaining photo slots counts stored photos" do
    assert_equal 5, @headache_log.remaining_photo_slots

    @headache_log.photos.attach(photo("photo.jpg"), photo("photo.jpg"))

    assert_equal 3, @headache_log.reload.remaining_photo_slots
  end

  test "destroying the log purges its photos" do
    @headache_log.photos.attach(photo("photo.jpg"))
    blob = @headache_log.photos.first.blob

    perform_enqueued_jobs { @headache_log.destroy }

    assert_not ActiveStorage::Blob.exists?(blob.id)
    assert_not ActiveStorage::Blob.service.exist?(blob.key)
  end

  test "destroying the user purges their photos" do
    @headache_log.photos.attach(photo("photo.jpg"))
    blob = @headache_log.photos.first.blob

    perform_enqueued_jobs { @headache_log.user.destroy }

    assert_not ActiveStorage::Blob.exists?(blob.id)
    assert_not ActiveStorage::Blob.service.exist?(blob.key)
  end

  private
    def photo(name)
      { io: file_fixture(name).open, filename: name }
    end
end
