class HeadacheLogExportsController < ApplicationController
  before_action :authenticate_user!

  def show
    send_data current_user.headache_logs.to_csv, filename: "headache_logs-#{Date.current}.csv"
  end
end
