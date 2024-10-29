class HeadacheLog < ApplicationRecord
  belongs_to :user
  validates :start_time, :intensity, presence: true
  validates :intensity, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }

  broadcasts_to ->(headache_log) { [ headache_log.user, "headache_logs" ] }, inserts_by: :prepend

  # filters
  scope :started_after, ->(start_time) { where("start_time >= ?", Date.parse(start_time).beginning_of_day) }
  scope :ended_before, ->(end_time) { where("end_time <= ?", Date.parse(end_time).end_of_day) }
  scope :with_triggers, ->(triggers) { where("triggers ILIKE ?", "%#{triggers}%") }
  scope :with_medication, ->(medication) { where("medication ILIKE ?", "%#{medication}%") }

  def self.filter_by_params(params)
    headache_logs = all
    headache_logs = headache_logs.started_after(params[:start_time]) if params[:start_time].present?
    headache_logs = headache_logs.ended_before(params[:end_time]) if params[:end_time].present?
    headache_logs = headache_logs.with_triggers(params[:triggers]) if params[:triggers].present?
    headache_logs = headache_logs.with_medication(params[:medication]) if params[:medication].present?
    headache_logs
  end
end
