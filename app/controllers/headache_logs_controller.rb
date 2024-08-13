class HeadacheLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_headache_log, only: %i[ show edit update destroy ]
  before_action :set_share_link, only: %i[ index ]

  # GET /headache_logs or /headache_logs.json
  def index
    @headache_logs = current_user.headache_logs.order(start_time: :desc)
  end

  # GET /headache_logs/1 or /headache_logs/1.json
  def show
  end

  # GET /headache_logs/new
  def new
    @headache_log = HeadacheLog.new
  end

  # GET /headache_logs/1/edit
  def edit
  end

  # POST /headache_logs or /headache_logs.json
  def create
    @headache_log = current_user.headache_logs.build(headache_log_params)

    respond_to do |format|
      if @headache_log.save
        format.html { redirect_to headache_log_url(@headache_log), notice: "Headache log was successfully created." }
        format.json { render :show, status: :created, location: @headache_log }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @headache_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /headache_logs/1 or /headache_logs/1.json
  def update
    respond_to do |format|
      if @headache_log.update(headache_log_params)
        format.html { redirect_to headache_log_url(@headache_log), notice: "Headache log was successfully updated." }
        format.json { render :show, status: :ok, location: @headache_log }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @headache_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /headache_logs/1 or /headache_logs/1.json
  def destroy
    @headache_log.destroy!

    respond_to do |format|
      format.html { redirect_to headache_logs_url, notice: "Headache log was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def generate_share_link
    share_token = current_user.generate_share_token
    @share_link = shared_logs_url(token: share_token.token)
    redirect_to headache_logs_path, notice: "Share link generated successfully."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_headache_log
      @headache_log = current_user.headache_logs.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def headache_log_params
      params.require(:headache_log).permit(:start_time, :end_time, :intensity, :notes)
    end

    def set_share_link
      @share_link = shared_logs_url(token: current_user.share_tokens.last.token)
    end
end
