class SharedLogsController < ApplicationController
  def index
    @share_token = ShareToken.active.find_by(token: params[:token])

    if @share_token
      @user = @share_token.user
      @headache_logs = @user.headache_logs.filtered_by(params).recent_first
      @headache_logs = @headache_logs.includes(medication_doses: :medication)
      @chart_data = @headache_logs.chart_data
      @medication_insights = @user.medication_insights_for(@headache_logs, params)
    else
      render plain: "This share link is invalid or has expired.", status: :unauthorized
    end
  end
end
