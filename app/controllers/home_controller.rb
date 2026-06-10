# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @users_count = User.count
    @logs_count = HeadacheLog.count
    @github_stars = fetch_github_stars
  end

  def privacy_policy
  end

  def faq
  end

  def imprint
  end

  def neurologist
  end

  def cluster_headache_diary
  end

  def cluster_headache_diary_template
  end

  def headache_diary_for_neurologist
  end

  def cluster_headache_oxygen_documentation
  end

  def sample_report
    @sample_user = Struct.new(:username).new("Demo Patient")
    @sample_headache_logs = HeadacheLog.sample_logs
    @sample_chart_data = HeadacheLog.chart_data_for(@sample_headache_logs)
  end

  def cluster_headache_app
  end

  def open_source_headache_tracker
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
end
