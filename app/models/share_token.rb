class ShareToken < ApplicationRecord
  belongs_to :user
  before_create :generate_token

  scope :active, -> { where("expires_at > ?", Time.current) }

  def active?
    expires_at > Time.current
  end

  private
  def generate_token
    self.token = SecureRandom.urlsafe_base64(16)
    self.expires_at = 30.days.from_now
  end
end
