class ShareToken < ApplicationRecord
  belongs_to :user
  before_create :generate_token

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(16)
    self.expires_at = 30.days.from_now
  end
end
