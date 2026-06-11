class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable

  validates :username, presence: true, uniqueness: true

  def self.signup_stats
    total_users = count
    users_seen_changelog = where.not(last_seen_changelog: nil).count
    users_with_logs = HeadacheLog.distinct.count(:user_id)

    {
      total_users: total_users,
      total_headache_logs: HeadacheLog.count,
      average_logs_per_user: users_with_logs.zero? ? 0.0 : HeadacheLog.count.fdiv(users_with_logs).round(1),
      users_seen_changelog: users_seen_changelog,
      changelog_seen_percentage: total_users.zero? ? 0 : (users_seen_changelog * 100.0 / total_users).round
    }
  end

  has_many :headache_logs, dependent: :destroy
  has_many :share_tokens, dependent: :destroy
  has_one :feedback_survey, dependent: :destroy

  after_create_commit :send_admin_notification

  def email_required?
    false
  end

  def current_share_token
    share_tokens.active.order(created_at: :desc).first
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
