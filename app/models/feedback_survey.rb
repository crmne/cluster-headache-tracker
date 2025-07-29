class FeedbackSurvey < ApplicationRecord
  belongs_to :user

  validates :usage_duration, presence: { message: "Please select how long you've been using the tracker" }
  validates :ease_of_use, presence: { message: "Please rate the ease of use (1-5 stars)" }, inclusion: { in: 1..5, message: "Ease of use must be between 1 and 5 stars" }
  validates :recommendation_likelihood, presence: { message: "Please rate how likely you are to recommend this tool (1-5 stars)" }, inclusion: { in: 1..5, message: "Recommendation likelihood must be between 1 and 5 stars" }
  validates :shared_with_doctor, inclusion: { in: [ true, false, nil ], message: "Please select if you've shared with your doctor" }

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
