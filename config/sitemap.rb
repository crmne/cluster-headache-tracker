# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://clusterheadachetracker.com"
SitemapGenerator::Sitemap.compress = false
SitemapGenerator::Sitemap.include_root = false

SitemapGenerator::Sitemap.create do
  # Add static pages
  add root_path, priority: 1.0, changefreq: "daily"
  add cluster_headache_diary_path, priority: 0.9, changefreq: "monthly"
  add cluster_headache_diary_template_path, priority: 0.9, changefreq: "monthly"
  add headache_diary_for_neurologist_path, priority: 0.9, changefreq: "monthly"
  add cluster_headache_oxygen_documentation_path, priority: 0.8, changefreq: "monthly"
  add sample_report_path, priority: 0.8, changefreq: "monthly"
  add cluster_headache_app_path, priority: 0.8, changefreq: "monthly"
  add open_source_headache_tracker_path, priority: 0.7, changefreq: "monthly"
  add neurologist_path, priority: 0.8, changefreq: "monthly"
  add faq_path, priority: 0.7, changefreq: "monthly"
  add imprint_path, priority: 0.7, changefreq: "monthly"
  add privacy_policy_path, priority: 0.7, changefreq: "monthly"
end
