class ChartsController < ApplicationController
  before_action :authenticate_user!

  def index
    @headache_logs = current_user.headache_logs.filtered_by(params).chronological
    @chart_data = @headache_logs.chart_data
    @medication_insights = current_user.medication_insights_for(@headache_logs, params)
  end
end
