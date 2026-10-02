class MedicationDose < ApplicationRecord
  include Exportable

  EFFECTIVENESS = %w[ helped no_effect made_worse ].freeze
  ONGOING_ATTACK_WINDOW = 12.hours

  belongs_to :user
  belongs_to :medication
  belongs_to :headache_log, optional: true, inverse_of: :medication_doses

  enum :effectiveness, EFFECTIVENESS.index_by(&:itself), validate: { allow_nil: true }

  attribute :taken_at, default: -> { Current.wall_clock_now }

  # Set when the headache log is already taken care of: it is saving its
  # own doses, or the legacy backfill must leave its text untouched.
  attr_accessor :skip_headache_log_refresh

  validates :taken_at, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0, less_than: 24 * 60 }, allow_nil: true
  validates :minutes_to_relief, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 24 * 60 }, allow_nil: true
  validate :medication_belongs_to_user, :headache_log_belongs_to_user

  before_validation :inherit_user_from_headache_log, :resolve_medication_name, :inherit_unit_from_medication
  before_create :attach_to_attack_in_progress, unless: :headache_log
  after_commit :refresh_headache_log, unless: -> { skip_headache_log_refresh || destroyed_by_association }

  scope :chronological, -> { order(:taken_at, :id) }
  scope :recent_first, -> { order(taken_at: :desc) }
  scope :rated, -> { where.not(effectiveness: nil) }
  scope :unrated, -> { where(effectiveness: nil) }
  scope :standalone, -> { where(headache_log_id: nil) }
  scope :reviewable, -> { joins(:medication).where.not(medications: { kind: "preventive" }) }
  scope :taken_between, ->(from, to) { where(taken_at: from.beginning_of_day..to.end_of_day) }

  class << self
    def format_amount(amount)
      ActiveSupport::NumberHelper.number_to_rounded(amount, precision: 2, strip_insignificant_zeros: true)
    end
  end

  # Typed into the picker for a medication that doesn't exist yet; the
  # medication is created with the dose.
  attr_reader :medication_name
  attr_accessor :medication_kind

  def medication_name=(name)
    @medication_name = name.to_s.squish.presence
  end

  def amount_label
    if amount
      [ self.class.format_amount(amount), unit ].compact.join(" ")
    end
  end

  def duration_label
    "#{duration_minutes} min" if duration_minutes
  end

  # Plain-text form kept in headache_logs.medication and the CSV export,
  # e.g. "oxygen 15 L/min 20 min". Medication::Legacy reads it back.
  def label
    [ medication.name, amount_label, duration_label ].compact.join(" ")
  end

  def minutes_until_attack_ended
    if headache_log&.end_time && headache_log.end_time > taken_at
      ((headache_log.end_time - taken_at) / 1.minute).round
    end
  end

  private
    def inherit_user_from_headache_log
      self.user ||= headache_log&.user
    end

    def resolve_medication_name
      if medication_name && user
        self.medication = user.medications.resolve(medication_name, kind: Medication::KINDS.include?(medication_kind) ? medication_kind : nil)
      end
    end

    def inherit_unit_from_medication
      if amount && unit.blank?
        self.unit = medication&.unit
      end
    end

    def medication_belongs_to_user
      if medication && medication.user_id != user_id
        errors.add(:medication, :invalid)
      end
    end

    def headache_log_belongs_to_user
      if headache_log && headache_log.user_id != user_id
        errors.add(:headache_log, :invalid)
      end
    end

    # A dose of anything but a preventive, taken while an attack is being
    # logged, treats that attack.
    def attach_to_attack_in_progress
      unless medication.preventive?
        self.headache_log = user.headache_logs.in_progress_at(taken_at, window: ONGOING_ATTACK_WINDOW).recent_first.first
      end
    end

    def refresh_headache_log
      if label_changed_for_headache_log?
        [ headache_log, previous_headache_log ].compact.uniq.reject(&:destroyed?).each(&:mirror_doses_into_legacy_medication_now)
      end
    end

    def label_changed_for_headache_log?
      destroyed? || previously_new_record? ||
        saved_change_to_medication_id? || saved_change_to_amount? || saved_change_to_unit? ||
        saved_change_to_duration_minutes? || saved_change_to_headache_log_id?
    end

    def previous_headache_log
      if saved_change_to_headache_log_id? && (id = headache_log_id_before_last_save)
        HeadacheLog.find_by(id: id)
      end
    end
end
