# The doses taken for an attack. While the free-text headache_logs.medication
# column is being retired, every change to a log's doses is mirrored into
# it (e.g. "oxygen 15 l/min 20 min, sumatriptan 6 mg"), so the column stays
# readable and a rollback to the text-only version loses nothing.
module HeadacheLog::Medicated
  extend ActiveSupport::Concern

  REVIEW_WINDOW = 24.hours

  included do
    has_many :medication_doses, -> { chronological }, dependent: :destroy, inverse_of: :headache_log
    accepts_nested_attributes_for :medication_doses, allow_destroy: true, reject_if: :blank_dose?

    before_save :mirror_doses_into_legacy_medication, if: :medication_doses_changed?

    scope :with_medication, ->(name) {
      pattern = "%#{sanitize_sql_like(name)}%"

      where(id: MedicationDose.joins(:medication).where("medications.name ILIKE ?", pattern).select(:headache_log_id))
        .or(where("headache_logs.medication ILIKE ?", pattern))
    }

    scope :in_progress_at, ->(time, window:) {
      where(start_time: ..time)
        .where("headache_logs.end_time >= :time OR (headache_logs.end_time IS NULL AND headache_logs.start_time >= :earliest)", time: time, earliest: time - window)
    }

    scope :awaiting_dose_review, -> {
      where(end_time: REVIEW_WINDOW.ago..).where(id: MedicationDose.unrated.reviewable.select(:headache_log_id))
    }
  end

  def medicated?
    medication_doses.any? || medication.present?
  end

  def medication_names
    if medication_doses.any?
      medication_doses.map { |dose| dose.medication.name }.uniq
    else
      medication_list
    end
  end

  def medication_text
    if medication_doses.any?
      legacy_medication_from(medication_doses)
    else
      medication.to_s
    end
  end

  def doses_awaiting_review
    medication_doses.select { |dose| dose.effectiveness.nil? && !dose.medication.preventive? }
  end

  # Builds doses from medication text such as a CSV import's "oxygen 15
  # min, sumatriptan 6mg", creating the medications on first mention.
  def take_medication_from(text)
    Medication::Legacy.parse(text).each do |entry|
      medication_doses.build \
        user: user,
        medication: user.medications.resolve(entry.name),
        taken_at: start_time,
        amount: entry.amount,
        unit: entry.unit,
        duration_minutes: entry.duration_minutes
    end
  end

  def mirror_doses_into_legacy_medication_now
    update(medication: legacy_medication_from(medication_doses.reload))
  end

  private
    def blank_dose?(attributes)
      attributes.values_at("id", "medication_id", "medication_name").all?(&:blank?)
    end

    def medication_doses_changed?
      medication_doses.target.any?(&:changed_for_autosave?)
    end

    def mirror_doses_into_legacy_medication
      # A log from before the backfill keeps what its text recorded.
      if medication_in_database.present? && medication_doses.none?(&:persisted?)
        take_medication_from(medication_in_database)
      end

      doses = medication_doses.to_a
      doses.each { |dose| dose.skip_headache_log_refresh = true }

      self.medication = legacy_medication_from(doses.reject(&:marked_for_destruction?))
    end

    def legacy_medication_from(doses)
      doses.sort_by.with_index { |dose, index| [ dose.taken_at, index ] }.map(&:label).join(", ").downcase.presence
    end
end
