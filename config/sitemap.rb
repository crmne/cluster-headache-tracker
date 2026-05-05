# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://clusterheadachetracker.com"
SitemapGenerator::Sitemap.compress = false
SitemapGenerator::Sitemap.include_root = false

SitemapGenerator::Sitemap.create do
  # Add static pages
  add root_path, priority: 1.0, changefreq: "daily"
  add neurologist_path, priority: 0.8, changefreq: "monthly"
  add faq_path, priority: 0.7, changefreq: "monthly"
  add imprint_path, priority: 0.7, changefreq: "monthly"
  add privacy_policy_path, priority: 0.7, changefreq: "monthly"
  add "/llms.txt", priority: 0.4, changefreq: "weekly"
  add "/llms-full.txt", priority: 0.4, changefreq: "weekly"
  add "/llm.json", priority: 0.4, changefreq: "weekly"
  add "/entity-map.json", priority: 0.4, changefreq: "weekly"
end
