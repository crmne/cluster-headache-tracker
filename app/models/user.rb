class User < ApplicationRecord
  include ReviewPrompting
  include Attacks

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable

  TIME_FORMATS = %w[ 12h 24h ].freeze

  validates :username, presence: true, uniqueness: true
  validates :locale, inclusion: { in: -> { I18n.available_locales.map(&:to_s) } }, allow_nil: true
  validates :time_format, inclusion: { in: TIME_FORMATS }, allow_nil: true

  normalizes :locale, :time_format, with: ->(value) { value.presence }, apply_to_nil: true

  def self.default_time_format_for(locale)
    locale.to_s == "en" ? "12h" : "24h"
  end

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

  def time_format_or_default
    time_format || self.class.default_time_format_for(locale || I18n.locale)
  end

  private

  def send_admin_notification
    AdminNotificationsMailer.new_user_notification(self).deliver_later
  end
end
