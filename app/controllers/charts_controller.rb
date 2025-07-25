class ChartsController < ApplicationController
  include ChartDataProcessor
  before_action :authenticate_user!

  def index
    @headache_logs = current_user.headache_logs.filter_by_params(params).order(:start_time)
    @chart_data = process_chart_data(@headache_logs)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
