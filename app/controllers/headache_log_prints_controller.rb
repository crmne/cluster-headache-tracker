class HeadacheLogPrintsController < ApplicationController
  include ReportDownload

  before_action :authenticate_user!

  def show
    @headache_logs = current_user.headache_logs.filtered_by(params).preloading_photos.recent_first.includes(medication_doses: :medication)

    respond_to do |format|
      format.html do
        @chart_data = @headache_logs.chart_data
        @medication_insights = current_user.medication_insights_for(@headache_logs, params)
      end
      format.pdf { send_report @headache_logs }
    end
  end
end
