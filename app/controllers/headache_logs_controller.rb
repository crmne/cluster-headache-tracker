require "csv"

class HeadacheLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_headache_log, only: %i[ show edit update destroy ]
  before_action :set_share_link, only: %i[ index ]

  # GET /headache_logs or /headache_logs.json
  def index
    @headache_logs = current_user.headache_logs.filter_by_params(params).order(start_time: :desc)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /headache_logs/1 or /headache_logs/1.json
  # def show
  # end

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
        format.html { redirect_to headache_logs_url, notice: "Headache log was successfully created.", status: :see_other }
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /headache_logs/1 or /headache_logs/1.json
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

  # DELETE /headache_logs/1 or /headache_logs/1.json
  def destroy
    @headache_log.destroy!

    respond_to do |format|
      format.html { redirect_to headache_logs_url, notice: "Headache log was successfully destroyed.", status: :see_other }
      format.turbo_stream
    end
  end

  def generate_share_link
    share_token = current_user.generate_share_token
    @share_link = shared_logs_url(token: share_token.token)
    flash[:generate_link] = true
    redirect_to headache_logs_path, notice: "Share link generated successfully."
  end

  def expire_share_link
    current_user.share_tokens.destroy_all
    redirect_to headache_logs_path, notice: "Share link has been expired."
  end

  def export
    @headache_logs = current_user.headache_logs.order(start_time: :desc)

    respond_to do |format|
      format.csv do
        csv_data = generate_csv(@headache_logs)
        if csv_data.is_a?(String) && csv_data.start_with?("Error")
          redirect_to headache_logs_path, alert: csv_data
        else
          send_data csv_data, filename: "headache_logs-#{Date.today}.csv"
        end
      end
    end
  end

  def import
    if params[:file].present?
      begin
        imported_logs = 0
        CSV.foreach(params[:file].path, headers: true, header_converters: :symbol) do |row|
          headache_log = current_user.headache_logs.new(
            start_time: parse_time(row[:start_time]),
            end_time: parse_time(row[:end_time]),
            intensity: row[:intensity],
            medication: row[:medication],
            triggers: row[:triggers],
            notes: row[:notes]
          )
          imported_logs += 1 if headache_log.save
        end
        redirect_to headache_logs_path, notice: "Successfully imported #{imported_logs} headache logs."
      rescue CSV::MalformedCSVError
        redirect_to headache_logs_path, alert: "Invalid CSV file format."
      rescue => e
        Rails.logger.error "Error importing CSV: #{e.message}"
        redirect_to headache_logs_path, alert: "An error occurred while importing the CSV file."
      end
    else
      redirect_to headache_logs_path, alert: "Please select a CSV file to import."
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_headache_log
    @headache_log = current_user.headache_logs.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def headache_log_params
    params.require(:headache_log).permit(:start_time, :end_time, :intensity, :notes, :medication, :triggers)
  end

  def set_share_link
    if last_token = current_user.share_tokens.last
      @share_link = shared_logs_url(token: last_token.token)
    end
  end

  def generate_csv(logs)
    CSV.generate(headers: true) do |csv|
      csv << [ "start_time", "end_time", "intensity", "medication", "triggers", "notes" ]

      logs.each do |log|
        csv << [
          log.start_time&.strftime("%Y-%m-%d %H:%M:%S"),
          log.end_time&.strftime("%Y-%m-%d %H:%M:%S"),
          log.intensity.to_s,
          log.medication.to_s,
          log.triggers.to_s,
          log.notes.to_s
        ]
      end
    end
  rescue => e
    Rails.logger.error "Error generating CSV: #{e.message}"
    "Error generating CSV. Please try again or contact support."
  end

  def parse_time(time_string)
    Time.zone.parse(time_string) if time_string.present?
  end
end
