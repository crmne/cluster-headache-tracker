class FeedbackSurvey < ApplicationRecord
  belongs_to :user

  validates :usage_duration, presence: true
  validates :ease_of_use, presence: true, inclusion: { in: 1..5 }
  validates :recommendation_likelihood, presence: true, inclusion: { in: 1..5 }

  serialize :versions, coder: JSON, type: Array
  serialize :most_useful_features, coder: JSON, type: Array

  USAGE_DURATIONS = [
    "Never used!",
    "Less than a week",
    "1-2 weeks",
    "2-4 weeks",
    "1-2 months",
    "Since launch (mid-August)"
  ].freeze

  VERSIONS = %w[Web iOS Android PWA].freeze

  FEATURES = [
    "Logging headache episodes",
    "Tracking medication use",
    "Identifying triggers",
    "Visualizing headache patterns",
    "Generating reports for doctors",
    "Exporting data"
  ].freeze
end
