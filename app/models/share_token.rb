class ShareToken < ApplicationRecord
  belongs_to :user

  has_secure_token
  before_create { self.expires_at = 30.days.from_now }

  scope :active, -> { where("expires_at > ?", Time.current) }

  def active?
    expires_at > Time.current
  end
end
