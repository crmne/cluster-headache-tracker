class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { Rails.env.development? && hotwire_native_app? }

  before_action :set_ongoing_headaches, if: :user_signed_in?
  before_action :set_locale
  helper_method :hotwire_native_app?

  private

  def set_ongoing_headaches
    @ongoing_headaches = current_user.headache_logs.where(end_time: nil).order(start_time: :desc)
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  # Devise redirect after sign up
  def after_sign_up_path_for(resource)
    headache_logs_path
  end
end
