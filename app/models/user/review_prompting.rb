module User::ReviewPrompting
  extend ActiveSupport::Concern

  REVIEW_PROMPT_MINIMUM_LOGS = 10
  REVIEW_PROMPT_INTERVAL = 4.months
  REVIEW_PROMPT_CALM_PERIOD = 6.hours

  # Asking for an app review is only fair once the app has proven useful, and never
  # while someone is in an attack or just getting over one.
  def review_prompt_due?
    headache_logs_count >= REVIEW_PROMPT_MINIMUM_LOGS && !recently_review_prompted? && calm?
  end

  def review_prompted
    touch :review_prompted_at
  end

  private
    def recently_review_prompted?
      review_prompted_at&.after?(REVIEW_PROMPT_INTERVAL.ago)
    end

    def calm?
      headache_logs.where(end_time: nil).or(headache_logs.where(end_time: REVIEW_PROMPT_CALM_PERIOD.ago..)).none?
    end
end
