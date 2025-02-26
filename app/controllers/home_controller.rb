# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @users_count = User.count
    @logs_count = HeadacheLog.count
  end

  def privacy_policy
  end

  def faq
  end

  def imprint
  end

  def neurologist
  end
end
