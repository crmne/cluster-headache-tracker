class AiVisibleContent
  SITE_URL = "https://clusterheadachetracker.com"
  SITE_NAME = "Cluster Headache Tracker"
  SITE_TITLE = "Cluster Headache Tracker & Diary"
  SITE_DESCRIPTION = "Free, privacy-focused cluster headache tracker and diary built by a fellow sufferer. Log attacks quickly, spot patterns, create doctor-ready reports, and keep health data private."
  ENTITY_ID = "#{SITE_URL}/#cluster-headache-tracker"
  FOUNDER_ID = "#{SITE_URL}/#carmine-paolino"
  WEBSITE_ID = "#{SITE_URL}/#website"
  SOFTWARE_ID = "#{SITE_URL}/#software"

  SOURCE_REPOSITORY_URL = "https://github.com/crmne/cluster-headache-tracker"
  IOS_REPOSITORY_URL = "https://github.com/crmne/cluster-headache-tracker-ios"
  ANDROID_REPOSITORY_URL = "https://github.com/crmne/cluster-headache-tracker-android"
  IOS_BETA_URL = "https://testflight.apple.com/join/GJsAQqz2"
  FOUNDER_URL = "https://paolino.me"
  CONTACT_EMAIL = "hello@clusterheadachetracker.com"
  DEMO_VIDEO_EMBED_URL = "https://www.youtube.com/embed/4HlsqANZdv8"
  DEMO_VIDEO_THUMBNAIL_URL = "https://i.ytimg.com/vi/4HlsqANZdv8/maxresdefault.jpg"
  DEMO_VIDEO_UPLOAD_DATE = "2024-12-21T13:39:46-08:00"

  config = YAML.safe_load(Rails.root.join("config/ai_visible_pages.yml").read)

  FEATURES = config.fetch("features").freeze
  TOPICS = config.fetch("topics").freeze
  PUBLIC_PAGES = config.fetch("pages").transform_values { |page| page.deep_symbolize_keys.freeze }.freeze

  SAME_AS = [
    SOURCE_REPOSITORY_URL,
    IOS_REPOSITORY_URL,
    ANDROID_REPOSITORY_URL,
    IOS_BETA_URL,
    FOUNDER_URL
  ].freeze

  class << self
    def page_for_path(path)
      PUBLIC_PAGES[normalize_path(path)]
    end

    def page_for_slug(slug)
      PUBLIC_PAGES.values.find { |page| page[:slug] == slug }
    end

    def public_indexable_path?(path)
      page_for_path(path).present? || ai_resource_path?(path)
    end

    def robots_directive_for(path)
      if public_indexable_path?(path)
        "index, follow, max-image-preview:large"
      else
        "noindex, nofollow"
      end
    end

    def absolute_url(path)
      if path.to_s.start_with?("http")
        path
      elsif path == "/"
        "#{SITE_URL}/"
      else
        "#{SITE_URL}#{path}"
      end
    end

    def llms_txt
      lines = []
      lines << "# #{SITE_NAME}"
      lines << ""
      lines << "> #{SITE_DESCRIPTION}"
      lines << ""
      append_about_section(lines)
      append_use_cases_section(lines)
      append_topics_section(lines)
      append_public_pages_section(lines)
      append_links_section(lines)
      lines.join("\n")
    end

    def llms_full_txt
      lines = []
      lines << llms_txt
      lines << "## Public Page Details"
      lines << ""

      PUBLIC_PAGES.each_value do |page|
        lines << page_markdown_content(page, include_url: true)
        lines << ""
        lines << "---"
        lines << ""
      end

      lines.join("\n").gsub(/\n{3,}/, "\n\n")
    end

    def llm_json
      {
        "name" => SITE_NAME,
        "tagline" => "Free cluster headache tracking by a fellow sufferer",
        "description" => SITE_DESCRIPTION,
        "category" => "HealthApplication",
        "url" => SITE_URL,
        "founder" => founder_schema,
        "target_audience" => [
          "People with cluster headaches",
          "Caregivers helping someone track cluster headaches",
          "Neurologists and healthcare providers reviewing patient-reported attack history"
        ],
        "use_cases" => [
          "Log cluster headache attacks during or after an attack",
          "Find frequency, timing, trigger, and medication response patterns",
          "Create doctor-ready reports and temporary share links",
          "Export personal headache logs as CSV"
        ],
        "features" => FEATURES,
        "privacy" => {
          "email_required" => false,
          "ads" => false,
          "data_sale" => false,
          "private_logs_in_ai_resources" => false,
          "summary" => "AI-visible files describe public product information only. Personal headache logs and shared reports are excluded."
        },
        "links" => link_catalog,
        "topics" => TOPICS,
        "license" => "GPL-3.0"
      }
    end

    def entity_map
      {
        "primary_entity" => organization_schema.merge(
          "source_pages" => PUBLIC_PAGES.values.map { |page| absolute_url(page[:path]) },
          "total_references" => PUBLIC_PAGES.size
        ),
        "founder" => founder_schema,
        "entities" => TOPICS.map { |topic| topic_entity(topic) },
        "page_resources" => page_resources,
        "generated_at" => Time.current.iso8601
      }
    end

    def page_markdown(slug)
      if page = page_for_slug(slug)
        page_markdown_content(page, include_url: true)
      end
    end

    def resource(resource_type, slug)
      case resource_type
      when "entity"
        entity_resource(slug)
      when "topic"
        topic_resource(slug)
      when "page"
        page_resource(slug)
      end
    end

    def json_ld_for(path:, logo_url:, android_apk_url:)
      page = page_for_path(path)
      nodes = [
        organization_schema(logo_url: logo_url),
        founder_schema,
        website_schema,
        software_schema(logo_url: logo_url, android_apk_url: android_apk_url)
      ]

      if page
        nodes << web_page_schema(page)
        nodes << breadcrumb_schema(page)
        nodes << faq_schema(page) if page[:faq].present?
        nodes << how_to_schema(page) if page[:how_to].present?
        nodes << video_schema if page[:slug] == "home"
      end

      {
        "@context" => "https://schema.org",
        "@graph" => nodes.compact
      }
    end

    def topic_slug(topic)
      topic.to_s.parameterize
    end

    private

    def normalize_path(path)
      normalized = path.to_s.split("?").first.presence || "/"
      normalized = normalized.chomp("/") unless normalized == "/"
      normalized
    end

    def ai_resource_path?(path)
      normalized = normalize_path(path)
      normalized.match?(%r{\A/(llms\.txt|llms-full\.txt|llm\.json|entity-map\.json)\z}) ||
        normalized.match?(%r{\A/ai/(entity|topic|page)/[a-z0-9-]+\.(json|ya?ml|md|txt)\z})
    end

    def append_about_section(lines)
      lines << "## About"
      lines << ""
      lines << "#{SITE_NAME} is a free, privacy-focused app for logging cluster headache attacks, finding patterns, and preparing doctor-ready reports."
      lines << ""
      lines << "- Builder: Carmine Paolino, a cluster headache sufferer"
      lines << "- Platforms: Web, PWA, iOS beta, Android beta"
      lines << "- Price: Free"
      lines << "- Open source: Yes, GPL-3.0"
      lines << "- Account model: Username and password, no email required"
      lines << "- Medical boundary: Tracking and reporting only, not medical advice"
      lines << ""
    end

    def append_use_cases_section(lines)
      lines << "## Key Use Cases"
      lines << ""
      lines << "- One-tap attack logging when the user is in severe pain"
      lines << "- Pattern review across timing, frequency, triggers, medications, and intensity"
      lines << "- Temporary read-only reports for neurologists and other healthcare providers"
      lines << "- CSV export for personal records"
      lines << "- Privacy-preserving headache diary without email-based identity"
      lines << ""
    end

    def append_topics_section(lines)
      lines << "## Key Topics"
      lines << ""
      TOPICS.each { |topic| lines << "- #{topic}" }
      lines << ""
    end

    def append_public_pages_section(lines)
      lines << "## Public Pages"
      lines << ""

      PUBLIC_PAGES.each_value do |page|
        lines << "- [#{page[:title]}](#{absolute_url(page[:path])}): #{page[:description]}"
      end

      lines << ""
      lines << "Private user dashboards, headache logs, charts, settings, feedback forms, and shared log URLs are intentionally excluded."
      lines << ""
    end

    def append_links_section(lines)
      lines << "## Links"
      lines << ""
      link_catalog.each do |name, url|
        lines << "- #{name.titleize}: #{url}"
      end
      lines << "- Full LLM brief: #{absolute_url('/llms-full.txt')}"
      lines << "- Structured product profile: #{absolute_url('/llm.json')}"
      lines << "- Entity map: #{absolute_url('/entity-map.json')}"
      lines << ""
    end

    def page_markdown_content(page, include_url:)
      lines = []
      lines << "# #{page[:title]}"
      lines << ""
      lines << "URL: #{absolute_url(page[:path])}" if include_url
      lines << "" if include_url
      lines << "> #{page[:description]}"
      lines << ""

      page[:sections].each do |section|
        lines << "## #{section[:heading]}"
        lines << ""
        section[:body].each { |paragraph| lines << paragraph }
        lines << ""
      end

      if page[:topics].present?
        lines << "## Topics"
        lines << ""
        page[:topics].each { |topic| lines << "- #{topic}" }
        lines << ""
      end

      if page[:faq].present?
        lines << "## FAQ"
        lines << ""
        page[:faq].each do |item|
          lines << "### #{item[:question]}"
          lines << ""
          lines << item[:answer]
          lines << ""
        end
      end

      lines.join("\n").gsub(/\n{3,}/, "\n\n").strip + "\n"
    end

    def link_catalog
      {
        "website" => SITE_URL,
        "source_code" => SOURCE_REPOSITORY_URL,
        "ios_beta" => IOS_BETA_URL,
        "ios_source_code" => IOS_REPOSITORY_URL,
        "android_apk" => AppConstants::ANDROID_APK_URL,
        "android_source_code" => ANDROID_REPOSITORY_URL,
        "cluster_headache_diary" => absolute_url("/cluster-headache-diary"),
        "diary_template" => absolute_url("/cluster-headache-diary-template"),
        "sample_report" => absolute_url("/sample-report"),
        "privacy_policy" => absolute_url("/privacy-policy"),
        "neurologist_page" => absolute_url("/neurologist"),
        "contact" => "mailto:#{CONTACT_EMAIL}"
      }
    end

    def organization_schema(logo_url: nil)
      data = {
        "@type" => "Organization",
        "@id" => ENTITY_ID,
        "name" => SITE_NAME,
        "url" => SITE_URL,
        "description" => SITE_DESCRIPTION,
        "founder" => { "@id" => FOUNDER_ID },
        "sameAs" => SAME_AS,
        "knowsAbout" => TOPICS,
        "contactPoint" => {
          "@type" => "ContactPoint",
          "email" => CONTACT_EMAIL,
          "contactType" => "support"
        }
      }

      if logo_url.present?
        data["logo"] = {
          "@type" => "ImageObject",
          "url" => logo_url
        }
      end

      data
    end

    def founder_schema
      {
        "@type" => "Person",
        "@id" => FOUNDER_ID,
        "name" => "Carmine Paolino",
        "url" => FOUNDER_URL,
        "description" => "Builder and maintainer of Cluster Headache Tracker, built from lived experience with cluster headaches.",
        "sameAs" => [
          FOUNDER_URL,
          "https://github.com/crmne"
        ],
        "knowsAbout" => [
          "Cluster headaches",
          "Ruby on Rails",
          "Hotwire Native",
          "Privacy-focused software"
        ]
      }
    end

    def website_schema
      {
        "@type" => "WebSite",
        "@id" => WEBSITE_ID,
        "url" => SITE_URL,
        "name" => SITE_NAME,
        "description" => SITE_DESCRIPTION,
        "publisher" => { "@id" => ENTITY_ID },
        "inLanguage" => "en",
        "potentialAction" => {
          "@type" => "RegisterAction",
          "name" => "Create a free tracking account",
          "target" => absolute_url("/users/sign_up")
        }
      }
    end

    def software_schema(logo_url:, android_apk_url:)
      {
        "@type" => "SoftwareApplication",
        "@id" => SOFTWARE_ID,
        "name" => SITE_NAME,
        "url" => SITE_URL,
        "description" => SITE_DESCRIPTION,
        "applicationCategory" => "HealthApplication",
        "operatingSystem" => "Web, iOS, Android",
        "isAccessibleForFree" => true,
        "offers" => {
          "@type" => "Offer",
          "price" => "0",
          "priceCurrency" => "USD"
        },
        "featureList" => FEATURES,
        "audience" => {
          "@type" => "Audience",
          "audienceType" => "People with cluster headaches and clinicians reviewing patient-reported headache history"
        },
        "creator" => { "@id" => FOUNDER_ID },
        "publisher" => { "@id" => ENTITY_ID },
        "sameAs" => SAME_AS,
        "softwareHelp" => absolute_url("/faq"),
        "privacyPolicy" => absolute_url("/privacy-policy"),
        "license" => "https://www.gnu.org/licenses/gpl-3.0.en.html",
        "codeRepository" => SOURCE_REPOSITORY_URL,
        "downloadUrl" => [ IOS_BETA_URL, android_apk_url ].compact,
        "image" => logo_url
      }.compact
    end

    def web_page_schema(page)
      type = if medical_page?(page)
        [ "WebPage", "MedicalWebPage" ]
      else
        "WebPage"
      end

      {
        "@type" => type,
        "@id" => "#{absolute_url(page[:path])}#webpage",
        "url" => absolute_url(page[:path]),
        "name" => page[:title],
        "description" => page[:description],
        "isPartOf" => { "@id" => WEBSITE_ID },
        "about" => page[:topics].map { |topic| topic_ref(topic) },
        "publisher" => { "@id" => ENTITY_ID },
        "inLanguage" => "en",
        "isAccessibleForFree" => true
      }
    end

    def breadcrumb_schema(page)
      return if page[:path] == "/"

      {
        "@type" => "BreadcrumbList",
        "@id" => "#{absolute_url(page[:path])}#breadcrumb",
        "itemListElement" => [
          {
            "@type" => "ListItem",
            "position" => 1,
            "name" => "Home",
            "item" => absolute_url("/")
          },
          {
            "@type" => "ListItem",
            "position" => 2,
            "name" => page[:title],
            "item" => absolute_url(page[:path])
          }
        ]
      }
    end

    def faq_schema(page)
      {
        "@type" => "FAQPage",
        "@id" => "#{absolute_url(page[:path])}#faq",
        "mainEntity" => page[:faq].map do |item|
          {
            "@type" => "Question",
            "name" => item[:question],
            "acceptedAnswer" => {
              "@type" => "Answer",
              "text" => item[:answer]
            }
          }
        end
      }
    end

    def how_to_schema(page)
      {
        "@type" => "HowTo",
        "@id" => "#{absolute_url(page[:path])}#how-to",
        "name" => page[:how_to][:name],
        "step" => page[:how_to][:steps].each_with_index.map do |step, index|
          {
            "@type" => "HowToStep",
            "position" => index + 1,
            "text" => step
          }
        end
      }
    end

    def video_schema
      {
        "@type" => "VideoObject",
        "@id" => "#{SITE_URL}/#demo-video",
        "name" => "Cluster Headache Tracker Demo",
        "description" => "A short demo of the Cluster Headache Tracker web app.",
        "embedUrl" => DEMO_VIDEO_EMBED_URL,
        "thumbnailUrl" => DEMO_VIDEO_THUMBNAIL_URL,
        "uploadDate" => DEMO_VIDEO_UPLOAD_DATE,
        "publisher" => { "@id" => ENTITY_ID }
      }.compact
    end

    def medical_page?(page)
      page[:topics].include?("Cluster headaches") ||
        page[:topics].include?("Neurology reports") ||
        page[:topics].include?("Oxygen treatment documentation")
    end

    def entity_resource(slug)
      case slug
      when "cluster-headache-tracker"
        with_context(organization_schema)
      when "carmine-paolino"
        with_context(founder_schema)
      end
    end

    def topic_resource(slug)
      if topic = TOPICS.find { |candidate| topic_slug(candidate) == slug }
        with_context(topic_entity(topic))
      end
    end

    def page_resource(slug)
      if page = page_for_slug(slug)
        with_context(web_page_schema(page).merge(
          "text" => page_markdown_content(page, include_url: true),
          "encoding" => [
            {
              "@type" => "MediaObject",
              "contentUrl" => absolute_url("/ai/page/#{page[:slug]}.md"),
              "encodingFormat" => "text/markdown"
            }
          ]
        ))
      end
    end

    def topic_entity(topic)
      pages = topic_pages(topic)

      {
        "@type" => "Thing",
        "@id" => absolute_url("/ai/topic/#{topic_slug(topic)}.json"),
        "name" => topic,
        "mentions" => pages.map { |page| absolute_url(page[:path]) },
        "mainEntityOfPage" => pages.map { |page| page_ref(page) }
      }
    end

    def topic_pages(topic)
      PUBLIC_PAGES.values.select { |page| page[:topics].include?(topic) }
    end

    def topic_ref(topic)
      {
        "@type" => "Thing",
        "@id" => absolute_url("/ai/topic/#{topic_slug(topic)}.json"),
        "name" => topic
      }
    end

    def page_ref(page)
      {
        "@type" => "WebPage",
        "@id" => "#{absolute_url(page[:path])}#webpage",
        "url" => absolute_url(page[:path]),
        "name" => page[:title]
      }
    end

    def page_resources
      PUBLIC_PAGES.values.to_h do |page|
        [
          page[:slug],
          [
            absolute_url("/ai/page/#{page[:slug]}.md"),
            absolute_url("/ai/page/#{page[:slug]}.json")
          ]
        ]
      end
    end

    def with_context(data)
      { "@context" => "https://schema.org" }.merge(data)
    end
  end
end
