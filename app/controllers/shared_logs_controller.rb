class SharedLogsController < ApplicationController
  include ChartDataProcessor

  def index
    @share_token = ShareToken.find_by(token: params[:token])

    if @share_token && @share_token.expires_at > Time.current
      @user = @share_token.user
      @headache_logs = @user.headache_logs.filter_by_params(params).order(start_time: :desc)
      @chart_data = process_chart_data(@headache_logs)
    else
      render plain: "This share link is invalid or has expired.", status: :unauthorized
    end
  end
end
