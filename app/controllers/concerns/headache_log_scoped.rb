module HeadacheLogScoped
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :set_headache_log
  end

  private
    def set_headache_log
      @headache_log = current_user.headache_logs.find(params[:headache_log_id])
    end
end
