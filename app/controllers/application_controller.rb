class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { Rails.env.development? && hotwire_native_app? }

  before_action :redirect_canonical_host
  before_action :set_ongoing_headaches, if: :user_signed_in?
  before_action :set_locale
  before_action :set_robots_tag_header
  helper_method :hotwire_native_app?

  private

  def redirect_canonical_host
    if request.host == "www.#{AppConstants::CANONICAL_HOST}"
      redirect_to "https://#{AppConstants::CANONICAL_HOST}#{request.fullpath}", status: :moved_permanently, allow_other_host: true
    end
  end

  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.request_id
    payload[:host] = request.host
    payload[:remote_ip] = request.remote_ip
    payload[:user_id] = current_user&.id if respond_to?(:current_user, true)
  end

  def set_ongoing_headaches
    @ongoing_headaches = current_user.headache_logs.where(end_time: nil).order(start_time: :desc)
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def set_robots_tag_header
    if request.get? || request.head?
      response.set_header("X-Robots-Tag", AiVisibleContent.robots_directive_for(request.path))
    end
  end

  # Devise redirect after sign up
  def after_sign_up_path_for(resource)
    headache_logs_path
  end
end
