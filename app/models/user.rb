class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username, presence: true, uniqueness: true

  has_many :headache_logs
  has_many :share_tokens
  has_one :feedback_survey

  after_create :send_admin_notification

  def email_required?
    false
  end

  def current_share_token
    share_tokens.active.order(created_at: :desc).first
  end

  def generate_share_token
    share_tokens.create!
  end

  def expire_share_link
    share_tokens.destroy_all
  end

  def will_save_change_to_email?
    false
  end

  def admin?
    username == "carmine"
  end

  private

  def send_admin_notification
    AdminNotificationsMailer.new_user_notification(self).deliver_later
  end
end
