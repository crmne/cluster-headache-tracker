class SharedLogsController < ApplicationController
  def show
    @share_token = ShareToken.find_by(token: params[:token])

    if @share_token && @share_token.expires_at > Time.current
      @user = @share_token.user
      @headache_logs = @user.headache_logs.order(start_time: :desc)
    else
      render plain: "This share link is invalid or has expired.", status: :unauthorized
    end
  end
end
