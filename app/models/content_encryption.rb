# What people log is encrypted at rest with Active Record encryption,
# non-deterministically, so equal values never look equal in the database.
# These are every column holding it. The database can't filter, sort or
# search them, so that happens in Ruby or on plaintext columns.
#
# Rows written before encryption are encrypted in place by
# `bin/rails encryption:encrypt`, which can be stopped and run again: it
# skips rows that are already encrypted. `bin/rails encryption:verify`
# counts what's left. Once that's zero in production,
# support_unencrypted_data can be turned off.
module ContentEncryption
  RECORDS = {
    "HeadacheLog" => %i[ medication triggers notes ],
    "Medication" => %i[ name schedule_note ],
    "FeedbackSurvey" => %i[ additional_features change_suggestion impact promotion_suggestions ]
  }.freeze

  extend self

  # Encrypts the rows still in plain text and yields each model's count.
  def encrypt_pending(batch_size: 500)
    models.to_h do |model|
      encrypted = model.find_each(batch_size: batch_size).count do |record|
        if unencrypted?(record)
          record.encrypt
          true
        end
      end

      yield model, encrypted if block_given?
      [ model, encrypted ]
    end
  end

  # How many rows of each model still hold plain text.
  def pending
    models.to_h do |model|
      [ model, model.find_each.count { |record| unencrypted?(record) } ]
    end
  end

  def unencrypted?(record)
    RECORDS.fetch(record.class.name).any? do |attribute|
      !record.read_attribute_before_type_cast(attribute).nil? && !record.encrypted_attribute?(attribute)
    end
  end

  private
    def models
      RECORDS.keys.map(&:constantize)
    end
end
