Rails.application.config.after_initialize do
  if defined?(Rails::Server)
    # Give the app a minute to fully initialize before generating sitemap
    SitemapRefreshJob.set(wait: 1.minute).perform_later
  end
end
