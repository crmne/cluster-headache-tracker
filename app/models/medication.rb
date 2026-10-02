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

  normalizes :name, with: ->(name) { name.squish }
  normalizes :unit, :schedule_note, with: ->(value) { value.squish.presence }
  normalizes :color, with: ->(color) { color.strip.downcase }

  validates :name, presence: true, length: { maximum: 60 }, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :color, format: { with: /\A#\h{6}\z/ }
  validates :default_dose, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :assign_defaults, on: :create

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :alphabetically, -> { order(Arel.sql("lower(medications.name)")) }
  scope :by_recent_use, -> {
    left_joins(:doses).group(:id).order(Arel.sql("MAX(medication_doses.taken_at) DESC NULLS LAST"), Arel.sql("lower(medications.name)"))
  }

  class << self
    def named(name)
      find_by("lower(medications.name) = ?", name.to_s.squish.downcase)
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

  def merge_into(medication)
    transaction do
      doses.update_all(medication_id: medication.id, updated_at: Time.current)
      doses.reset
      destroy!
    end
  end

  private
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
