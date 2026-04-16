# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @users_count = User.count
    @logs_count = HeadacheLog.count
    @github_stars = fetch_github_stars
  end

  private

  def fetch_github_stars
    Rails.cache.fetch("github_stars", expires_in: 1.hour) do
      response = Net::HTTP.get(URI("https://api.github.com/repos/crmne/cluster-headache-tracker"))
      JSON.parse(response)["stargazers_count"] || 0
    rescue StandardError
      0
    end
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
