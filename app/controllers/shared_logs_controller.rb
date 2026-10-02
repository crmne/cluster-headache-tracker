class SharedLogsController < ApplicationController
  include ReportDownload

  def index
    @share_token = ShareToken.active.find_by(token: params[:token])

    if @share_token
      @user = @share_token.user
      @headache_logs = @user.headache_logs.filtered_by(params).recent_first

      respond_to do |format|
        format.html { @chart_data = @headache_logs.chart_data }
        format.pdf { send_report @headache_logs }
      end
    else
      render plain: "This share link is invalid or has expired.", status: :unauthorized
    end
  end
end
