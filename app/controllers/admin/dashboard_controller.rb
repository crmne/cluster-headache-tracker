class Admin::DashboardController < Admin::BaseController
  def index
    @total_users = User.count
    @total_headache_logs = HeadacheLog.count
    @users_with_logs = User.joins(:headache_logs).distinct.count
    @average_logs_per_user = @users_with_logs > 0 ? (@total_headache_logs.to_f / @users_with_logs).round(1) : 0

    # Recent activity
    @recent_users = User.order(created_at: :desc).limit(5)

    # Changelog stats
    current_version = "v2.0.0"
    @users_seen_changelog = User.where(last_seen_changelog: current_version).count
    @changelog_percentage = @total_users > 0 ? ((@users_seen_changelog.to_f / @total_users) * 100).round : 0
  end
end
