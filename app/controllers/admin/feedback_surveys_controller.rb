require "csv"

class Admin::FeedbackSurveysController < Admin::BaseController
  def index
    @feedback_surveys = FeedbackSurvey.includes(:user).order(created_at: :desc)
    @stats = {
      total_responses: @feedback_surveys.count,
      average_ease: @feedback_surveys.average(:ease_of_use)&.round(2),
      average_recommendation: @feedback_surveys.average(:recommendation_likelihood)&.round(2),
      shared_with_doctor: @feedback_surveys.where(shared_with_doctor: true).count,
      platforms: @feedback_surveys.map(&:versions).flatten.tally,
      features: @feedback_surveys.map(&:most_useful_features).flatten.tally
    }
  end

  def show
    @feedback_survey = FeedbackSurvey.find(params[:id])
  end

  def import
    if params[:file].present?
      result = import_from_csv(params[:file])
      message = "Import complete: #{result[:imported]} imported"
      message += ", #{result[:skipped_existing]} skipped (already have feedback)" if result[:skipped_existing] > 0
      message += ", #{result[:failed]} failed" if result[:failed] > 0

      redirect_to admin_feedback_surveys_path, notice: message
    else
      redirect_to admin_feedback_surveys_path, alert: "Please select a CSV file to import"
    end
  rescue CSV::MalformedCSVError => e
    Rails.logger.error "CSV Import Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to admin_feedback_surveys_path, alert: "CSV format error: #{e.message}. Make sure you're uploading a valid Tally CSV export."
  rescue => e
    Rails.logger.error "Import Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to admin_feedback_surveys_path, alert: "Import failed: #{e.message}"
  end

  def destroy
    @feedback_survey = FeedbackSurvey.find(params[:id])
    username = @feedback_survey.user.username
    @feedback_survey.destroy
    redirect_to admin_feedback_surveys_path, notice: "Feedback from #{username} has been reset"
  end

  def destroy_all
    count = FeedbackSurvey.count
    FeedbackSurvey.destroy_all
    redirect_to admin_feedback_surveys_path, notice: "All #{count} feedback entries have been reset"
  end

  private

  def import_from_csv(file)
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
        username = "tally_#{email_username}_#{respondent_id}"
      else
        username = "tally_#{respondent_id}"
      end

      # Check if user already exists
      user = User.find_by(username: username)

      if user
        # User exists - skip if they already have feedback
        if user.feedback_survey.present?
          Rails.logger.info "Skipping import: user #{username} already has feedback"
          stats[:skipped_existing] += 1
          next
        end
        Rails.logger.info "Using existing user: #{username}"
      else
        # User doesn't exist - create new one
        begin
          user = User.create!(username: username, password: SecureRandom.hex(16))
          Rails.logger.info "Created new user: #{username}"
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "Failed to create user #{username}: #{e.message}"
          stats[:failed] += 1
          next
        end
      end

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

      # Ensure user is saved
      user.save! if user.new_record?

      # Create feedback survey
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

      stats[:imported] += 1
    rescue => e
      Rails.logger.error "Failed to create feedback for #{username}: #{e.message}"
      stats[:failed] += 1
    end

    stats
  end
end
