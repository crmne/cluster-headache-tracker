class ShareLinksController < ApplicationController
  before_action :authenticate_user!

  def create
    @share_token = current_user.share_tokens.create!
    @share_link = shared_logs_url(token: @share_token.token)

    respond_to do |format|
      format.html do
        flash[:generate_link] = true
        redirect_to headache_logs_path, notice: t(".generated")
      end
      format.turbo_stream
    end
  end

  def destroy
    current_user.share_tokens.destroy_all

    respond_to do |format|
      format.html { redirect_to headache_logs_path, notice: t(".expired") }
      format.turbo_stream
    end
  end
end
