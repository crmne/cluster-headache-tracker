class HeadacheLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_headache_log, only: %i[ show edit update destroy ]

  def index
    @headache_logs = filtered_headache_logs.recent_first
    set_share_link
  end

  def new
    @headache_log = HeadacheLog.new
  end

  def edit
  end

  def create
    @headache_log = current_user.headache_logs.build(headache_log_params)

    respond_to do |format|
      if @headache_log.save
        format.html { redirect_to headache_logs_url, notice: "Headache log was successfully created.", status: :see_other }
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @headache_log.update(headache_log_params)
        format.html { redirect_to headache_logs_url, notice: "Headache log was successfully updated." }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @headache_log.destroy!

    respond_to do |format|
      format.html { redirect_to headache_logs_url, notice: "Headache log was successfully destroyed.", status: :see_other }
      format.turbo_stream
    end
  end

  private
    def filtered_headache_logs
      current_user.headache_logs.filtered_by(params)
    end

    def current_share_token
      @current_share_token ||= current_user.current_share_token
    end

    def headache_log_params
      params.require(:headache_log).permit(:start_time, :end_time, :intensity, :notes, :medication, :triggers)
    end

    def set_headache_log
      @headache_log = current_user.headache_logs.find(params[:id])
    end

    def set_share_link
      @share_token = current_share_token

      if @share_token
        @share_link = shared_logs_url(token: @share_token.token)
      end
    end
end
