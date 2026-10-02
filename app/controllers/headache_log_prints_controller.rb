class HeadacheLogPrintsController < ApplicationController
  include ReportDownload

  before_action :authenticate_user!

  def show
    @headache_logs = current_user.headache_logs.filtered_by(params).recent_first

    respond_to do |format|
      format.html { @chart_data = @headache_logs.chart_data }
      format.pdf { send_report @headache_logs }
    end
  end
end
