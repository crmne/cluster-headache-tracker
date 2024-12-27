class SitemapRefreshJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Refreshing sitemap..."
    Rails.application.load_tasks
    Rake::Task["sitemap:create"].invoke
    Rails.logger.info "Sitemap refresh complete"
  end
end
