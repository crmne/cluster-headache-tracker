class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { Rails.env.development? && hotwire_native_app? }

  before_action :set_ongoing_headaches, if: :user_signed_in?
  before_action :set_locale
  helper_method :hotwire_native_app?

  # Hotwire Native navigation endpoint
  def recede_historical_location
    Rails.logger.info "🎯 Rails: recede_historical_location called by #{request.user_agent}"

    if helpers.native_app_with_tabs?
      Rails.logger.info "📱 Rails: Native app detected, rendering navigation page"
      render html: "<html><body><script>console.log('Navigating for native app'); window.location.href = '/headache_logs';</script></body></html>".html_safe
    else
      Rails.logger.info "🌐 Rails: Web app, redirecting normally"
      redirect_to headache_logs_path
    end
  end

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
