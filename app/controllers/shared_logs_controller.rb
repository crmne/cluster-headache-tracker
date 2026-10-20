class SharedLogsController < ApplicationController
  include ReportDownload

  allow_without_health_data_consent

  def index
    @share_token = ShareToken.active.find_by(token: params[:token])

    if @share_token.nil?
      render plain: t(".invalid"), status: :unauthorized
    elsif @share_token.paused?
      render plain: t(".paused"), status: :forbidden
    else
      show_shared_logs
    end
  end

  private
    def show_shared_logs
      @user = @share_token.user
      @headache_logs = @user.headache_logs.filtered_by(params).recent_first
      @headache_logs = @headache_logs.includes(medication_doses: :medication)

      respond_to do |format|
        format.html do
          @chart_data = @headache_logs.chart_data
          @medication_insights = @user.medication_insights_for(@headache_logs, params)
        end
        format.pdf { send_report @headache_logs }
      end
    end
end
