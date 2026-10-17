# Health data is processed only with explicit consent (GDPR Art. 9(2)(a)),
# given with a checkbox when signing up. Accounts created before that are
# asked once, the next time they use the app (HealthDataConsentRequired).
module User::HealthDataConsent
  extend ActiveSupport::Concern

  included do
    # The sign-up form's checkbox. Users created any other way leave it nil
    # and are asked on their first visit instead.
    attribute :health_data_consent, :boolean

    validate :health_data_consent_given, on: :create, unless: -> { health_data_consent.nil? }
    before_create :record_health_data_consent, if: :health_data_consent
  end

  def consented?
    consented_at.present?
  end

  def consent_to_health_data
    touch :consented_at unless consented?
  end

  private
    def health_data_consent_given
      unless health_data_consent
        errors.add :base, :health_data_consent_required
      end
    end

    def record_health_data_consent
      self.consented_at = Time.current
    end
end
