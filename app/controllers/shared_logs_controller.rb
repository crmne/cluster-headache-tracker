class SharedLogsController < ApplicationController
  def index
    @share_token = ShareToken.active.find_by(token: params[:token])

    if @share_token
      @user = @share_token.user
      @headache_logs = @user.headache_logs.filtered_by(params).recent_first
      @chart_data = @headache_logs.chart_data
    else
      render plain: t(".invalid"), status: :unauthorized
    end
  end
end
