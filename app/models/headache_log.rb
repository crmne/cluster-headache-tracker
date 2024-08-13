class HeadacheLog < ApplicationRecord
  belongs_to :user
  validates :start_time, :intensity, presence: true
  validates :intensity, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }

  broadcasts_to ->(headache_log) { [headache_log.user, "headache_logs"] }, inserts_by: :prepend
end
