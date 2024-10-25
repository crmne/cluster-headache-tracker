class ApplicationController < ActionController::Base
  before_action :set_ongoing_headaches, if: :user_signed_in?
  helper_method :hotwire_native_app?

  private

  def set_ongoing_headaches
    @ongoing_headaches = current_user.headache_logs.where(end_time: nil).order(start_time: :desc)
  end
end
