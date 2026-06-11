class HeadacheLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_headache_log, only: %i[ show edit update destroy ]

  def index
    @headache_logs = filtered_headache_logs.recent_first
    set_share_link
  end

  def new
    @headache_log = current_user.headache_logs.new
  end

  def edit
  end

  def create
    @headache_log = current_user.headache_logs.build(headache_log_params)

    if @headache_log.save
      redirect_to headache_logs_url, notice: "Headache log was successfully created.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @headache_log.update(headache_log_params)
      redirect_to headache_logs_url, notice: "Headache log was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @headache_log.destroy!

    redirect_to headache_logs_url, notice: "Headache log was successfully destroyed.", status: :see_other
  end

  private
    def filtered_headache_logs
      current_user.headache_logs.filtered_by(params)
    end

    def headache_log_params
      params.expect(headache_log: [ :start_time, :end_time, :intensity, :notes, :medication, :triggers ])
    end

    def set_headache_log
      @headache_log = current_user.headache_logs.find(params[:id])
    end

    def set_share_link
      @share_token = current_user.current_share_token

      if @share_token
        @share_link = shared_logs_url(token: @share_token.token)
      end
    end
end
