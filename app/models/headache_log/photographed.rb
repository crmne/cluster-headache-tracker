module HeadacheLog::Photographed
  extend ActiveSupport::Concern

  PHOTO_LIMIT = 5
  PHOTO_MAX_SIZE = 10.megabytes
  PHOTO_CONTENT_TYPES = %w[ image/jpeg image/png image/heic image/heif image/webp ].freeze

  included do
    # Variants are re-encoded as JPEG so HEIC from iPhones displays everywhere, and
    # stripped of metadata so EXIF location never leaves the server.
    has_many_attached :photos do |attachable|
      attachable.variant :thumb, resize_to_fill: [ 320, 320 ], format: :jpeg, saver: { strip: true, quality: 80 }
      attachable.variant :large, resize_to_limit: [ 2048, 2048 ], format: :jpeg, saver: { strip: true, quality: 85 }
    end

    validate :photos_are_acceptable

    # Unlike with_attached_photos, preloading leaves aggregate queries (stats) free of attachment joins.
    scope :preloading_photos, -> { preload(:photos_attachments) }
  end

  # Photos already stored, leaving out uploads still pending in an unsaved form.
  def stored_photos
    photos.attachments.select(&:persisted?)
  end

  def remaining_photo_slots
    [ PHOTO_LIMIT - stored_photos.size, 0 ].max
  end

  private
    def photos_are_acceptable
      if photos.size > PHOTO_LIMIT
        errors.add :photos, :too_many, count: PHOTO_LIMIT
      end

      photos.each do |photo|
        unless photo.content_type.in?(PHOTO_CONTENT_TYPES)
          errors.add :photos, :invalid_content_type, filename: photo.filename.to_s
        end

        if photo.byte_size > PHOTO_MAX_SIZE
          errors.add :photos, :too_large, filename: photo.filename.to_s, size: PHOTO_MAX_SIZE / 1.megabyte
        end
      end
    end
end
