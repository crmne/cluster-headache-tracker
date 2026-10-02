class TimelinesController < ApplicationController
  before_action :authenticate_user!

  def show
    @timeline = Timeline.new(current_user, before: params[:before])
  end
end
