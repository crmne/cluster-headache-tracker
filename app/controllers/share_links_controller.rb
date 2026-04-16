class ShareLinksController < ApplicationController
  before_action :authenticate_user!

  def create
    @share_token = current_user.generate_share_token
    @share_link = shared_logs_url(token: @share_token.token)

    respond_to do |format|
      format.html do
        flash[:generate_link] = true
        redirect_to headache_logs_path, notice: "Share link generated successfully."
      end
      format.turbo_stream
    end
  end

  def destroy
    current_user.expire_share_link

    respond_to do |format|
      format.html { redirect_to headache_logs_path, notice: "Share link has been expired." }
      format.turbo_stream
    end
  end
end
