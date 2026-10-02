# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://clusterheadachetracker.com"
SitemapGenerator::Sitemap.compress = false
SitemapGenerator::Sitemap.include_root = false

SitemapGenerator::Sitemap.create do
  pages = {
    "/" => { priority: 1.0, changefreq: "daily" },
    "/cluster-headache-diary" => { priority: 0.9, changefreq: "monthly" },
    "/cluster-headache-diary-template" => { priority: 0.9, changefreq: "monthly" },
    "/headache-diary-for-neurologist" => { priority: 0.9, changefreq: "monthly" },
    "/cluster-headache-oxygen-documentation" => { priority: 0.8, changefreq: "monthly" },
    "/sample-report" => { priority: 0.8, changefreq: "monthly" },
    "/cluster-headache-app" => { priority: 0.8, changefreq: "monthly" },
    "/open-source-headache-tracker" => { priority: 0.7, changefreq: "monthly" },
    "/neurologist" => { priority: 0.8, changefreq: "monthly" },
    "/faq" => { priority: 0.7, changefreq: "monthly" },
    "/imprint" => { priority: 0.7, changefreq: "monthly" },
    "/privacy-policy" => { priority: 0.7, changefreq: "monthly" }
  }

  # Every language version lists all of its translations (hreflang), English being the x-default
  pages.each do |path, options|
    alternates = I18n.available_locales.map do |locale|
      { href: AiVisibleContent.absolute_url(AiVisibleContent.localized_path(path, locale)), lang: locale.to_s }
    end
    alternates << { href: AiVisibleContent.absolute_url(path), lang: "x-default" }

    I18n.available_locales.each do |locale|
      add AiVisibleContent.localized_path(path, locale), **options, alternates: alternates
    end
  end
end
