class ChartsController < ApplicationController
  before_action :authenticate_user!

  def index
    @headache_logs = current_user.headache_logs.filtered_by(params).chronological
    @chart_data = @headache_logs.chart_data
  end
end
