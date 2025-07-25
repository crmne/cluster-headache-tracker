class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username, presence: true, uniqueness: true

  has_many :headache_logs
  has_many :share_tokens

  def email_required?
    false
  end

  def generate_share_token
    share_tokens.create
  end

  def will_save_change_to_email?
    false
  end

  def admin?
    username == "carmine"
  end
end
