# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://clusterheadachetracker.com"

SitemapGenerator::Sitemap.create do
  # Add static pages
  add root_path, priority: 1.0, changefreq: "daily"
  add faq_path, priority: 0.7, changefreq: "monthly"
  add imprint_path, priority: 0.7, changefreq: "monthly"
  add privacy_policy_path, priority: 0.7, changefreq: "monthly"
  add feedback_path, priority: 0.7, changefreq: "monthly"
end
