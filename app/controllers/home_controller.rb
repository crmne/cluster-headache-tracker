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
    @sample_headache_logs = sample_headache_logs
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

  def sample_headache_logs
    base_date = Date.current - 18.days

    [
      sample_headache_log(base_date, "02:10", "02:55", 8, "oxygen 15 min", "sleep disruption", "Right eye pain, paced during attack, relief after oxygen."),
      sample_headache_log(base_date + 1.day, "01:42", "02:34", 9, "oxygen 20 min", "sleep disruption", "Woke from sleep, tearing, restless, shadow remained after relief."),
      sample_headache_log(base_date + 3.days, "22:18", "22:56", 7, "sumatriptan", "alcohol", "Late evening attack after alcohol exposure, relief after medication."),
      sample_headache_log(base_date + 5.days, "03:05", "04:12", 10, "oxygen 25 min", "sleep disruption", "Severe right-sided attack, oxygen helped but relief was slower."),
      sample_headache_log(base_date + 6.days, "13:24", "13:58", 6, "oxygen 12 min", "none noted", "Shorter daytime attack, returned to work after relief."),
      sample_headache_log(base_date + 8.days, "00:38", "01:29", 8, "oxygen 18 min", "sleep disruption", "Woke from sleep, nasal congestion, relief after oxygen."),
      sample_headache_log(base_date + 10.days, "02:48", "03:31", 9, "oxygen 20 min", "sleep disruption", "Pacing and tearing, no medication side effects noted."),
      sample_headache_log(base_date + 12.days, "21:16", "22:04", 7, "sumatriptan", "weather change", "Evening attack, medication helped within the hour."),
      sample_headache_log(base_date + 13.days, "04:12", "04:49", 8, "oxygen 15 min", "sleep disruption", "Oxygen relief, mild shadow afterward."),
      sample_headache_log(base_date + 15.days, "01:08", "02:02", 9, "oxygen 20 min", "sleep disruption", "Typical overnight pattern, attack ended after oxygen.")
    ]
  end

  def sample_headache_log(date, start_time, end_time, intensity, medication, triggers, notes)
    HeadacheLog.new(
      start_time: Time.zone.parse("#{date} #{start_time}"),
      end_time: Time.zone.parse("#{date} #{end_time}"),
      intensity: intensity,
      medication: medication,
      triggers: triggers,
      notes: notes
    )
  end
end
