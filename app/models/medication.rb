class Medication < ApplicationRecord
  include Schedule

  KINDS = %w[ abortive oxygen preventive other ].freeze
  UNITS = %w[ mg mcg g ml L/min IU units puffs sprays tablets ].freeze
  COLORS = %w[ #0ea5e9 #8b5cf6 #f59e0b #10b981 #ef4444 #ec4899 #6366f1 #14b8a6 #84cc16 #f97316 #64748b #a855f7 ].freeze
  OXYGEN_COLOR = "#0ea5e9"
  OXYGEN_UNIT = "L/min"

  belongs_to :user
  has_many :doses, class_name: "MedicationDose", dependent: :destroy

  enum :kind, KINDS.index_by(&:itself), validate: true

  # Names and schedule notes are health data, encrypted at rest, so the
  # database never compares or sorts them: name_digest stands in for the
  # name in lookups and the unique index, and ordering happens in Ruby.
  encrypts :name, :schedule_note

  normalizes :name, with: ->(name) { name.squish }
  normalizes :unit, :schedule_note, with: ->(value) { value.squish.presence }
  normalizes :color, with: ->(color) { color.strip.downcase }

  validates :name, presence: true, length: { maximum: 60 }
  validates :color, format: { with: /\A#\h{6}\z/ }
  validates :default_dose, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  validate :name_unique_for_user

  before_validation :assign_defaults, on: :create
  before_validation :digest_name

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  class << self
    def alphabetically
      all.sort_by(&:name_sort_key)
    end

    # Most recently taken first; never-taken ones last, alphabetically.
    def by_recent_use
      medications = all.to_a
      last_taken = MedicationDose.where(medication_id: medications.map(&:id)).group(:medication_id).maximum(:taken_at)

      medications.sort_by do |medication|
        taken_at = last_taken[medication.id]
        [ taken_at ? 0 : 1, -taken_at.to_f, medication.name_sort_key ]
      end
    end

    def named(name)
      find_by(name_digest: digest_name(name))
    end

    # A keyed digest of the name, ignoring case and spacing, so names can
    # be matched without storing them in the clear.
    def digest_name(name)
      OpenSSL::HMAC.hexdigest("SHA256", name_digest_key, name.to_s.squish.downcase)
    end

    # Finds the medication by name, ignoring case, or creates it. Used by
    # the inline "new medication" picker, CSV import and the legacy backfill.
    def resolve(name, kind: nil)
      named(name) || create!(name: name, kind: kind || kind_for(name))
    rescue ActiveRecord::RecordNotUnique
      named(name)
    end

    def kind_for(name)
      case name.to_s.downcase
      when Legacy::OXYGEN then "oxygen"
      when Legacy::PREVENTIVES then "preventive"
      when Legacy::ABORTIVES then "abortive"
      else "other"
      end
    end

    private
      def name_digest_key
        @name_digest_key ||= ActiveRecord::Encryption.key_generator.derive_key_from("medications.name_digest")
      end
  end

  def archived?
    archived_at.present?
  end

  def archived=(value)
    self.archived_at = ActiveModel::Type::Boolean.new.cast(value) ? (archived_at || Time.current) : nil
  end

  def display_color
    color.presence || default_color
  end

  def default_dose_label
    if default_dose
      [ MedicationDose.format_amount(default_dose), unit ].compact.join(" ")
    end
  end

  def name_sort_key
    name.to_s.downcase
  end

  def merge_into(medication)
    transaction do
      doses.update_all(medication_id: medication.id, updated_at: Time.current)
      doses.reset
      destroy!
    end
  end

  private
    def digest_name
      self.name_digest = self.class.digest_name(name)
    end

    def name_unique_for_user
      if user && name.present? && user.medications.where.not(id: id).exists?(name_digest: name_digest)
        errors.add :name, :taken
      end
    end

    def assign_defaults
      self.color = display_color
      self.unit = OXYGEN_UNIT if oxygen? && unit.blank?
    end

    def default_color
      if oxygen?
        OXYGEN_COLOR
      else
        COLORS[Zlib.crc32(name.to_s.downcase) % COLORS.size]
      end
    end
end
