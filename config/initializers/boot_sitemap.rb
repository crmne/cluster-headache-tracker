Rails.application.config.after_initialize do
  if defined?(Rails::Server)
    # Give the app a few seconds to fully initialize before generating sitemap
    SitemapRefreshJob.set(wait: 10.seconds).perform_later
  end
end
