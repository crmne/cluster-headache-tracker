class ShareToken < ApplicationRecord
  belongs_to :user

  has_secure_token
  before_create { self.expires_at = 30.days.from_now }

  scope :active, -> { where("expires_at > ?", Time.current) }

  # Showing someone's logs is processing their health data, so a link stops
  # showing them while its owner hasn't consented (User::HealthDataConsent),
  # and works again once they do, until it expires.
  def paused?
    !user.consented?
  end
end
