# Signed-in people who haven't consented to the processing of their health
# data (User::HealthDataConsent) are sent to the consent page before anything
# else. Public pages, Settings (to delete the account instead) and the
# exports (their data is theirs either way) stay open.
module HealthDataConsentRequired
  extend ActiveSupport::Concern

  included do
    before_action :require_health_data_consent, if: :health_data_consent_missing?
  end

  class_methods do
    def allow_without_health_data_consent(**options)
      skip_before_action :require_health_data_consent, **options
    end
  end

  private
    def health_data_consent_missing?
      user_signed_in? && !devise_controller? && !current_user.consented?
    end

    def require_health_data_consent
      if request.get? && request.format.html?
        store_location_for :user, request.fullpath
        redirect_to health_data_consent_path
      else
        head :forbidden
      end
    end
end
