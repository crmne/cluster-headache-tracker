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

  FEATURES = [
    "One-tap cluster headache attack logging",
    "Start and end time tracking with automatic duration",
    "Pain intensity tracking",
    "Medication, trigger, and note capture",
    "Charts for frequency, cycles, timing, and treatment response",
    "Temporary read-only share links for healthcare providers",
    "CSV export",
    "PWA, iOS beta, Android beta, and web access",
    "Username-only accounts with no email requirement",
    "Open-source Rails codebase"
  ].freeze

  TOPICS = [
    "Cluster headaches",
    "Headache diary",
    "Headache diary template",
    "Headache diary for neurologist visits",
    "Attack logging",
    "KIP scale",
    "Oxygen treatment documentation",
    "Oxygen response tracking",
    "Neurology reports",
    "Medication effectiveness",
    "Circadian headache patterns",
    "Privacy-focused health tracking",
    "Open-source health software",
    "Open-source headache tracker",
    "Cluster headache app",
    "Progressive web app",
    "Hotwire Native"
  ].freeze

  SAME_AS = [
    SOURCE_REPOSITORY_URL,
    IOS_REPOSITORY_URL,
    ANDROID_REPOSITORY_URL,
    IOS_BETA_URL,
    FOUNDER_URL
  ].freeze

  PUBLIC_PAGES = {
    "/" => {
      slug: "home",
      path: "/",
      title: SITE_TITLE,
      description: SITE_DESCRIPTION,
      topics: [
        "Cluster headaches",
        "Headache diary",
        "Attack logging",
        "Oxygen treatment documentation",
        "Privacy-focused health tracking",
        "Open-source health software",
        "Progressive web app",
        "Hotwire Native"
      ],
      sections: [
        {
          heading: "Product Summary",
          body: [
            "Cluster Headache Tracker is a free web, PWA, iOS beta, and Android beta app for people with cluster headaches.",
            "It is built around attack-time use: a large one-tap logging flow captures the attack first, then details can be added later.",
            "The app turns personal logs into charts, tables, CSV exports, and temporary doctor share links."
          ]
        },
        {
          heading: "Why It Exists",
          body: [
            "The app was built by Carmine Paolino, a cluster headache sufferer, after paper diaries, spreadsheets, and generic headache apps were too slow during attacks.",
            "Its goal is practical tracking for treatment conversations, including clearer documentation of attack frequency and treatment response."
          ]
        },
        {
          heading: "Privacy Position",
          body: [
            "Accounts use username and password only. Email addresses are not required.",
            "The app has no ads and does not sell user health data.",
            "Personal headache logs and shared reports are intentionally excluded from AI-visible resources."
          ]
        }
      ],
      faq: [
        {
          question: "What is Cluster Headache Tracker?",
          answer: "Cluster Headache Tracker is a free app for logging cluster headache attacks, finding patterns, and sharing clear reports with doctors."
        },
        {
          question: "Is Cluster Headache Tracker free?",
          answer: "Yes. The app is free to use and open source. Donations are optional."
        },
        {
          question: "Does Cluster Headache Tracker require an email address?",
          answer: "No. Accounts use a username and password, so people can start tracking without giving an email address."
        },
        {
          question: "Can people use it during an attack?",
          answer: "Yes. The core flow is designed around one-tap attack logging, with details added later when the user can think clearly."
        }
      ],
      how_to: {
        name: "How to track a cluster headache attack",
        steps: [
          "Create a free username and password account.",
          "Tap the main logging button when an attack starts.",
          "Stop the timer when the attack ends.",
          "Add intensity, medication, triggers, and notes when able.",
          "Review charts or share a temporary report link with a healthcare provider."
        ]
      }
    },
    "/cluster-headache-diary" => {
      slug: "cluster-headache-diary",
      path: "/cluster-headache-diary",
      title: "Free Cluster Headache Diary",
      description: "Free cluster headache diary and tracker for logging attack time, duration, KIP-style intensity, medication, oxygen response, triggers, and notes.",
      topics: [
        "Cluster headaches",
        "Headache diary",
        "Attack logging",
        "KIP scale",
        "Medication effectiveness",
        "Oxygen response tracking",
        "Neurology reports"
      ],
      sections: [
        {
          heading: "Diary Purpose",
          body: [
            "This page explains how to keep a practical cluster headache diary that captures attack timing, duration, intensity, medication, oxygen response, triggers, and notes.",
            "The product flow emphasizes one-tap attack logging first, then adding details later when the user is able."
          ]
        },
        {
          heading: "Cluster-Specific Fields",
          body: [
            "The diary focuses on start and end times, KIP-style intensity, medication and oxygen notes, possible triggers, and appointment-ready reporting.",
            "The page links to the printable diary template, sample report, neurologist visit guide, and oxygen documentation page."
          ]
        }
      ],
      faq: [
        {
          question: "What should a cluster headache diary include?",
          answer: "A useful diary should include attack start and end times, duration, intensity, medication or oxygen notes, treatment response, triggers, and free-form notes."
        },
        {
          question: "Can details be added after the attack?",
          answer: "Yes. The tracker is designed to capture the attack quickly, then let users add medication, triggers, and notes later."
        }
      ],
      how_to: {
        name: "How to keep a cluster headache diary",
        steps: [
          "Start the attack timer when pain begins.",
          "Stop the timer when the attack ends.",
          "Add KIP-style intensity, medication, oxygen use, triggers, and notes.",
          "Review charts for timing, duration, and frequency patterns.",
          "Print, export, or share a temporary report for appointments."
        ]
      }
    },
    "/cluster-headache-diary-template" => {
      slug: "cluster-headache-diary-template",
      path: "/cluster-headache-diary-template",
      title: "Cluster Headache Diary Template",
      description: "Printable cluster headache diary template for attack time, duration, intensity, medication, oxygen response, triggers, and notes.",
      topics: [
        "Headache diary template",
        "Headache diary",
        "Cluster headaches",
        "KIP scale",
        "Medication effectiveness",
        "Oxygen response tracking"
      ],
      sections: [
        {
          heading: "Printable Template",
          body: [
            "The template provides a plain printable table for attack date, start time, end time, duration, intensity, medication or oxygen, response, triggers, and notes.",
            "It is designed for paper use during a cycle and for people who want a low-friction alternative before using the app."
          ]
        },
        {
          heading: "App Alternative",
          body: [
            "The app keeps the same core diary fields while adding one-tap logging, automatic duration, charts, exports, and temporary report links.",
            "The printable template is intentionally plain because paper is useful only when it stays easy to use."
          ]
        }
      ],
      faq: [
        {
          question: "Can the template be printed?",
          answer: "Yes. The page includes a print-friendly table for recording cluster headache attacks on paper."
        },
        {
          question: "Can the CSV be imported later?",
          answer: "Yes. The CSV uses the app's standard headache log columns."
        }
      ]
    },
    "/headache-diary-for-neurologist" => {
      slug: "headache-diary-for-neurologist",
      path: "/headache-diary-for-neurologist",
      title: "Headache Diary for Neurologist Visits",
      description: "Prepare a headache diary for neurologist appointments with attack timing, duration, intensity, medication response, oxygen notes, triggers, and reports.",
      topics: [
        "Headache diary for neurologist visits",
        "Neurology reports",
        "Headache diary",
        "Cluster headaches",
        "Medication effectiveness",
        "Circadian headache patterns",
        "Oxygen response tracking"
      ],
      sections: [
        {
          heading: "Appointment Preparation",
          body: [
            "This page explains what to bring to a neurology visit: attack timing, duration, intensity, medication response, oxygen notes, triggers, and reports.",
            "The goal is to help patients bring structured attack history rather than reconstructing a cycle from memory."
          ]
        },
        {
          heading: "Report Output",
          body: [
            "Cluster Headache Tracker can create printable reports, CSV exports, and temporary share links for clinician review.",
            "The page links to the public sample report and provider-facing neurologist page."
          ]
        }
      ],
      faq: [
        {
          question: "What headache diary data is useful for a neurologist?",
          answer: "Attack frequency, start time, end time, duration, intensity, medication or oxygen use, treatment response, triggers, and notes can make the history easier to review."
        },
        {
          question: "Can reports be shared without a doctor account?",
          answer: "Yes. Users can generate temporary read-only share links that do not require the clinician to create an account."
        }
      ]
    },
    "/cluster-headache-oxygen-documentation" => {
      slug: "cluster-headache-oxygen-documentation",
      path: "/cluster-headache-oxygen-documentation",
      title: "Cluster Headache Oxygen Documentation",
      description: "Track cluster headache attack frequency, duration, oxygen use, and treatment response for clinician and insurance conversations without making treatment promises.",
      topics: [
        "Oxygen treatment documentation",
        "Oxygen response tracking",
        "Cluster headaches",
        "Neurology reports",
        "Medication effectiveness",
        "Headache diary"
      ],
      sections: [
        {
          heading: "Documentation Boundary",
          body: [
            "This page explains that oxygen treatment must be discussed with and prescribed by a clinician.",
            "The tracker cannot make treatment decisions, but it can help users bring clearer documentation of attack frequency, duration, oxygen use, and response history."
          ]
        },
        {
          heading: "Tracked Response Data",
          body: [
            "Users can log whether oxygen or medication was used, how long the attack lasted, and whether relief was noticed.",
            "Reports summarize timing, duration, intensity, and treatment notes for clinician or insurance conversations."
          ]
        }
      ],
      faq: [
        {
          question: "Does the tracker replace an oxygen prescription?",
          answer: "No. The tracker does not diagnose, prescribe, or make treatment decisions. It helps organize patient-entered data for clinician and insurance conversations."
        },
        {
          question: "What oxygen-related details can be logged?",
          answer: "Users can record oxygen use in medication notes, add duration or response notes, and compare attack duration and intensity across logged attacks."
        }
      ]
    },
    "/sample-report" => {
      slug: "sample-report",
      path: "/sample-report",
      title: "Sample Cluster Headache Report",
      description: "Public fictional sample cluster headache report showing attack summaries, timing, intensity, treatment response notes, charts, and detailed log entries.",
      topics: [
        "Neurology reports",
        "Headache diary",
        "Cluster headaches",
        "Medication effectiveness",
        "Circadian headache patterns",
        "Oxygen response tracking"
      ],
      sections: [
        {
          heading: "Fictional Demo Report",
          body: [
            "The sample report is a public fictional demo showing what private user reports can look like.",
            "It includes summary stats, attack timing, treatment response notes, and detailed log entries."
          ]
        },
        {
          heading: "Privacy Boundary",
          body: [
            "Real reports remain private unless a user creates a temporary share link.",
            "Public search engines can see the fictional sample report, not personal dashboards, private logs, or shared report URLs."
          ]
        }
      ],
      faq: [
        {
          question: "Is the sample report real patient data?",
          answer: "No. The sample report is fictional and public for demonstration."
        },
        {
          question: "Can real reports be printed?",
          answer: "Yes. Real reports can be printed from the browser, saved as PDF, exported as CSV, or shared through a temporary read-only link."
        }
      ]
    },
    "/cluster-headache-app" => {
      slug: "cluster-headache-app",
      path: "/cluster-headache-app",
      title: "Cluster Headache App",
      description: "Free cluster headache app for web, PWA, iOS beta, and Android beta. One-tap attack logging, charts, CSV export, privacy, and doctor-ready reports.",
      topics: [
        "Cluster headache app",
        "Progressive web app",
        "Hotwire Native",
        "Attack logging",
        "Headache diary",
        "Privacy-focused health tracking",
        "Neurology reports"
      ],
      sections: [
        {
          heading: "App Access",
          body: [
            "Cluster Headache Tracker is available on the web, as a PWA, and through iOS and Android beta shells.",
            "The page explains one-tap attack logging, charts, reports, CSV export, and privacy defaults."
          ]
        },
        {
          heading: "Cluster-Specific Workflow",
          body: [
            "The app prioritizes fast timer-based logging instead of long forms during attacks.",
            "Users can add details later and review the same data from another device."
          ]
        }
      ],
      faq: [
        {
          question: "Is Cluster Headache Tracker available as an app?",
          answer: "Yes. It can be used on the web, installed as a PWA, and accessed through iOS and Android beta apps."
        },
        {
          question: "Does the app work without email signup?",
          answer: "Yes. Accounts use username and password only."
        }
      ]
    },
    "/open-source-headache-tracker" => {
      slug: "open-source-headache-tracker",
      path: "/open-source-headache-tracker",
      title: "Open Source Headache Tracker",
      description: "Open-source, privacy-focused headache tracker for cluster headache attacks. Rails codebase, username-only accounts, CSV export, and doctor-ready reports.",
      topics: [
        "Open-source headache tracker",
        "Open-source health software",
        "Privacy-focused health tracking",
        "Headache diary",
        "Cluster headaches"
      ],
      sections: [
        {
          heading: "Open Source Trust",
          body: [
            "This page explains why public source code matters for a health diary.",
            "The Rails codebase can be inspected, improved, and self-hosted by technical users."
          ]
        },
        {
          heading: "Privacy Defaults",
          body: [
            "The app uses username-only accounts, avoids ads, does not sell personal headache data, supports CSV export, and keeps private dashboards outside public SEO files.",
            "The project exists for the cluster headache community rather than broad wellness tracking."
          ]
        }
      ],
      faq: [
        {
          question: "Is the headache tracker open source?",
          answer: "Yes. The web app source code is public on GitHub under GPL-3.0."
        },
        {
          question: "Can users export their data?",
          answer: "Yes. Users can export their headache logs as CSV."
        }
      ]
    },
    "/faq" => {
      slug: "faq",
      path: "/faq",
      title: "Cluster Headache Tracker FAQ",
      description: "Real answers about cluster headaches, attack tracking, privacy, doctor sharing, and why this free tracker exists.",
      topics: [
        "Cluster headaches",
        "Headache diary",
        "Attack logging",
        "Oxygen treatment documentation",
        "Privacy-focused health tracking",
        "Medication effectiveness"
      ],
      sections: [
        {
          heading: "Cluster Headache Questions",
          body: [
            "The FAQ explains how cluster headaches differ from migraine, why cycles and attack timing matter, and why tracking can help patients explain what is happening.",
            "It keeps the tone direct because the product is built for people who are already dealing with severe pain."
          ]
        },
        {
          heading: "Tracker Questions",
          body: [
            "The FAQ covers one-tap logging, chart review, CSV export, doctor share links, phone access, and the no-email account model.",
            "It also states that the app is free, open source, and built by a fellow sufferer."
          ]
        }
      ],
      faq: [
        {
          question: "What are cluster headaches?",
          answer: "Cluster headaches are severe one-sided headache attacks that often occur in cycles and can repeat at similar times of day."
        },
        {
          question: "How do users share reports with a doctor?",
          answer: "Users generate a secure, temporary share link that shows charts, tables, medication notes, and logged attacks without requiring the doctor to create an account."
        },
        {
          question: "Can users export their data?",
          answer: "Yes. Users can export their headache logs as CSV."
        },
        {
          question: "Is personal headache data exposed to AI crawlers?",
          answer: "No. AI-visible resources describe only public product pages and public product facts, not private headache logs or shared reports."
        }
      ]
    },
    "/neurologist" => {
      slug: "neurologist",
      path: "/neurologist",
      title: "Cluster Headache Tracker for Neurologists",
      description: "A free cluster headache tracking tool for patients that produces clean reports, clear patterns, and documentation for clinical conversations.",
      topics: [
        "Cluster headaches",
        "Neurology reports",
        "Oxygen treatment documentation",
        "Medication effectiveness",
        "Circadian headache patterns",
        "Headache diary"
      ],
      sections: [
        {
          heading: "Provider Use Case",
          body: [
            "Patients can bring structured attack history instead of vague recollections.",
            "Reports include attack timestamps, duration, intensity, medications, triggers, notes, charts, and printable tables.",
            "Share links are temporary, read-only, and do not require provider accounts."
          ]
        },
        {
          heading: "Clinical Boundary",
          body: [
            "Cluster Headache Tracker is a tracking and reporting tool.",
            "It is not a substitute for professional medical advice, diagnosis, or treatment."
          ]
        }
      ],
      faq: [
        {
          question: "Does a clinician need an account to view a report?",
          answer: "No. The patient can create a temporary share link that opens a read-only report."
        },
        {
          question: "What data appears in a shared report?",
          answer: "Shared reports include logged attacks, timestamps, duration, intensity, medication notes, trigger notes, charts, and printable tables."
        }
      ]
    },
    "/privacy-policy" => {
      slug: "privacy-policy",
      path: "/privacy-policy",
      title: "Privacy Policy for Cluster Headache Tracker",
      description: "Privacy policy for Cluster Headache Tracker, including username-only accounts, health log storage, sharing controls, export rights, and data handling.",
      topics: [
        "Privacy-focused health tracking",
        "Headache diary",
        "Open-source health software"
      ],
      sections: [
        {
          heading: "Privacy Summary",
          body: [
            "Users provide a username and headache log data.",
            "The app does not require email addresses for accounts.",
            "Users can export data as CSV and control temporary sharing links."
          ]
        },
        {
          heading: "Data Use",
          body: [
            "Data is used to provide headache tracking, charts, reports, and product improvements.",
            "Personal logs are not sold and are not included in AI-visible content files."
          ]
        }
      ]
    },
    "/imprint" => {
      slug: "imprint",
      path: "/imprint",
      title: "Cluster Headache Tracker Imprint",
      description: "Legal imprint and contact details for Cluster Headache Tracker, a non-commercial tool maintained by Carmine Paolino.",
      topics: [
        "Open-source health software",
        "Privacy-focused health tracking"
      ],
      sections: [
        {
          heading: "Maintainer",
          body: [
            "Cluster Headache Tracker is maintained by Carmine Paolino as a non-commercial platform for people managing cluster headaches.",
            "Contact email: hello@clusterheadachetracker.com"
          ]
        },
        {
          heading: "Disclaimer",
          body: [
            "The website is for informational purposes and personal tracking.",
            "It is not a substitute for professional medical advice, diagnosis, or treatment."
          ]
        }
      ]
    }
  }.freeze

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
