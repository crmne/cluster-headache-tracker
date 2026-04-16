class HeadacheLogPrintsController < ApplicationController
  before_action :authenticate_user!

  def show
    @headache_logs = current_user.headache_logs.filtered_by(params).recent_first
    @chart_data = @headache_logs.chart_data
  end
end
