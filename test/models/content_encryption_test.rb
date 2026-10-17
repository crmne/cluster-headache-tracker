require "test_helper"

class ContentEncryptionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "every column holding what people log is encrypted" do
    ContentEncryption::RECORDS.each do |class_name, attributes|
      assert_equal attributes.sort, class_name.constantize.encrypted_attributes.to_a.sort, class_name
    end
  end

  test "logs are stored as ciphertext, never the words people wrote" do
    log = @user.headache_logs.create!(start_time: 1.hour.ago, intensity: 8,
      notes: "Woke at 3am, right eye", triggers: "red wine", medication: "verapamil 240 mg")

    %i[ notes triggers medication ].each do |column|
      stored = stored_value(HeadacheLog, log, column)

      assert_not_includes stored, log.public_send(column)
      assert ActiveRecord::Encryption.encryptor.encrypted?(stored), column
    end

    assert_equal "Woke at 3am, right eye", log.reload.notes
  end

  test "medications, their schedule notes and feedback answers are stored as ciphertext" do
    medication = @user.medications.create!(name: "Verapamil", kind: "preventive", schedule_note: "With breakfast")
    feedback = users(:two).create_feedback_survey!(usage_duration: "1-2 weeks", ease_of_use: 4, recommendation_likelihood: 5,
      impact: "Fewer attacks since I started tracking oxygen")

    assert_not_includes stored_value(Medication, medication, :name), "Verapamil"
    assert_not_includes stored_value(Medication, medication, :schedule_note), "breakfast"
    assert_not_includes stored_value(FeedbackSurvey, feedback, :impact), "oxygen"
  end

  test "the same words encrypt differently every time" do
    first, second = 2.times.map { |hours| @user.headache_logs.create!(start_time: (hours + 1).hours.ago, intensity: 5, notes: "Same note") }

    assert_not_equal stored_value(HeadacheLog, first, :notes), stored_value(HeadacheLog, second, :notes)
  end

  test "encrypting existing rows encrypts only what's still plain text, and can run again" do
    log = headache_logs(:one)
    store_plain_text HeadacheLog, log, notes: "Written before encryption"
    store_plain_text Medication, medications(:oxygen), schedule_note: "Before encryption"

    assert ContentEncryption.unencrypted?(log.reload)
    assert_equal 1, ContentEncryption.pending[HeadacheLog]
    assert_equal 1, ContentEncryption.pending[Medication]

    encrypted = ContentEncryption.encrypt_pending(batch_size: 1)

    assert_equal 1, encrypted[HeadacheLog]
    assert_equal 1, encrypted[Medication]
    assert_equal({ HeadacheLog => 0, Medication => 0, FeedbackSurvey => 0 }, ContentEncryption.pending)
    assert_equal "Written before encryption", log.reload.notes
    assert_not_includes stored_value(HeadacheLog, log, :notes), "Written"

    assert_equal({ HeadacheLog => 0, Medication => 0, FeedbackSurvey => 0 }, ContentEncryption.encrypt_pending)
  end

  test "encrypting doesn't touch the rows' timestamps" do
    log = headache_logs(:one)
    store_plain_text HeadacheLog, log, notes: "Written before encryption"

    assert_no_changes -> { log.reload.updated_at } do
      ContentEncryption.encrypt_pending
    end
  end

  private
    def stored_value(model, record, column)
      model.connection.select_value(model.where(id: record.id).select(column).to_sql)
    end

    def store_plain_text(model, record, **values)
      # Written as SQL, so the value skips encryption like rows from before it
      model.where(id: record.id).update_all(values.map { |column, value| model.sanitize_sql_array([ "#{column} = ?", value ]) }.join(", "))
    end
end
