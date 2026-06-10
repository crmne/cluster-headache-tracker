require "csv"

class FeedbackSurvey < ApplicationRecord
  belongs_to :user

  validates :usage_duration, presence: true
  validates :ease_of_use, :recommendation_likelihood, presence: true, inclusion: { in: 1..5, message: "must be between 1 and 5 stars" }

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

  class << self
    def stats
      {
        total_responses: count,
        average_ease: average(:ease_of_use)&.round(2),
        average_recommendation: average(:recommendation_likelihood)&.round(2),
        shared_with_doctor: where(shared_with_doctor: true).count,
        platforms: all.flat_map(&:versions).tally,
        features: all.flat_map(&:most_useful_features).tally
      }
    end

    def import_tally_csv(file)
      stats = { imported: 0, skipped_existing: 0, failed: 0 }
      # Read the file with more lenient parsing options
      csv_text = File.read(file.path, encoding: "UTF-8")
      # Remove BOM if present
      csv_text = csv_text.sub(/\A\xEF\xBB\xBF/, "")

      # Parse with options that handle Tally's export format
      CSV.parse(csv_text,
                headers: true,
                liberal_parsing: true,
                quote_char: '"',
                col_sep: ",",
                skip_blanks: true,
                strip: true) do |row|
        next if row["Submission ID"].blank?

        username = tally_username_from(row)
        user = tally_user_for(username)

        if user.nil?
          stats[:failed] += 1
          next
        end

        if user.feedback_survey.present?
          Rails.logger.info "Skipping import: user #{username} already has feedback"
          stats[:skipped_existing] += 1
          next
        end

        create_tally_feedback(user, row)
        stats[:imported] += 1
      rescue => e
        Rails.logger.error "Failed to create feedback for #{username}: #{e.message}"
        stats[:failed] += 1
      end

      stats
    end

    private
      def tally_username_from(row)
        # Try to extract email from various fields in the response
        email_regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/
        email = nil

        # Check all row values for an email address
        row.each do |_, value|
          if value && (match = value.to_s.match(email_regex))
            email = match[0].downcase
            break
          end
        end

        # Create username with tally_ prefix
        # Use lowercase respondent ID to ensure consistency
        respondent_id = row["Respondent ID"].downcase

        if email
          # Use email username part (before @) for readability, but include respondent ID for uniqueness
          email_username = email.split("@").first
          "tally_#{email_username}_#{respondent_id}"
        else
          "tally_#{respondent_id}"
        end
      end

      def tally_user_for(username)
        user = User.find_by(username: username)

        if user
          Rails.logger.info "Using existing user: #{username}"
          user
        else
          user = User.create!(username: username, password: SecureRandom.hex(16))
          Rails.logger.info "Created new user: #{username}"
          user
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Failed to create user #{username}: #{e.message}"
        nil
      end

      def create_tally_feedback(user, row)
        submitted_at = DateTime.parse(row["Submitted at"])

        # Parse versions
        versions = []
        versions << "Web" if row["Which version are you using or would you be interested in using? (Select all that apply) (Web)"] == "true"
        versions << "iOS" if row["Which version are you using or would you be interested in using? (Select all that apply) (iOS)"] == "true"
        versions << "Android" if row["Which version are you using or would you be interested in using? (Select all that apply) (Android)"] == "true"
        versions << "PWA" if row["Which version are you using or would you be interested in using? (Select all that apply) (PWA (Installable Web App))"] == "true"

        # Parse features
        features = []
        features << "Logging headache episodes" if row["What features do you find most useful? (Select all that apply) (Logging headache episodes)"] == "true"
        features << "Tracking medication use" if row["What features do you find most useful? (Select all that apply) (Tracking medication use)"] == "true"
        features << "Identifying triggers" if row["What features do you find most useful? (Select all that apply) (Identifying triggers)"] == "true"
        features << "Visualizing headache patterns" if row["What features do you find most useful? (Select all that apply) (Visualizing headache patterns)"] == "true"
        features << "Generating reports for doctors" if row["What features do you find most useful? (Select all that apply) (Generating reports for doctors)"] == "true"
        features << "Exporting data" if row["What features do you find most useful? (Select all that apply) (Exporting data)"] == "true"

        # Parse shared with doctor
        shared_with_doctor = case row["Have you used the feature to share your headache data with your doctor?"]
        when "Yes" then true
        when "No" then false
        else nil
        end

        # Parse mobile interest
        mobile_interest = case row["Would you be interested in a mobile app version of the Cluster Headache Tracker?"]
        when "Yes, for iOS" then "ios"
        when "Yes, for Android" then "android"
        when /Yes.*both/i then "both"
        when /PWA/i then "pwa"
        else "none"
        end

        feedback = user.build_feedback_survey(
          usage_duration: row["How long have you been using the Cluster Headache Tracker?"],
          versions: versions,
          most_useful_features: features,
          additional_features: row["What additional features would you like to see in the Cluster Headache Tracker?"],
          ease_of_use: row["How easy is the Cluster Headache Tracker to use?"].to_i,
          shared_with_doctor: shared_with_doctor,
          impact: row["How has the Cluster Headache Tracker impacted your management of cluster headaches in the short time it's been available?"],
          change_suggestion: row["If you could change one thing about the Cluster Headache Tracker, what would it be?"],
          recommendation_likelihood: row["How likely are you to recommend the Cluster Headache Tracker to others with cluster headaches?"].to_i,
          promotion_suggestions: row["As an early user, what suggestions do you have for improving or promoting the Cluster Headache Tracker?"],
          mobile_interest: mobile_interest,
          user_agent: "Imported from Tally"
        )

        # Set timestamps manually to preserve original submission date
        feedback.created_at = submitted_at
        feedback.updated_at = submitted_at
        feedback.save!
      end
  end
end
