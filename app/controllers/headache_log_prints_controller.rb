class HeadacheLogPrintsController < ApplicationController
  before_action :authenticate_user!

  def show
    @headache_logs = current_user.headache_logs.filtered_by(params).recent_first.includes(medication_doses: :medication)
    @chart_data = @headache_logs.chart_data
    @medication_insights = current_user.medication_insights_for(@headache_logs, params)
  end
end
