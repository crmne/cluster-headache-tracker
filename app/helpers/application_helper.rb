module ApplicationHelper
  def time_ago_in_words(from_time, format: :long)
    return unless from_time

    # Treat all times as local by using Time.local components
    from_local = Time.local(from_time.year, from_time.month, from_time.day,
                            from_time.hour, from_time.min, from_time.sec)
    now_local = Time.current

    distance = (now_local - from_local).round

    case format
    when :short
      if distance < 1.hour
        pluralize((distance / 60.0).round, "min")
      elsif distance < 24.hours
        pluralize((distance / 1.hour).round, "hour")
      else
        pluralize((distance / 1.day).round, "day")
      end
    else
      super(from_time)
    end
  end

  def canonical_url
    request.base_url + request.path
  end

  def app_title
    "Cluster Headache Tracker | Free Tracking Tool"
  end

  def app_short_description
    "Track and Manage Cluster Headaches | Free Privacy-Focused App"
  end

  def app_description
    "Track your cluster headaches, identify triggers, and share doctor reports to get oxygen therapy approved. Free, private tool used by 340+ patients. iOS & Android apps available."
  end

  def page_title
    if content_for(:title)
      [ content_for(:title), app_title ].compact.join(" | ")
    else
      [ app_title, app_short_description ].compact.join(" | ")
    end
  end

  def page_meta_description
    content_for?(:meta_description) ? content_for(:meta_description) : app_description
  end

  # New: Add specific meta descriptions for key pages
  def home_meta_description
    "Free cluster headache tracking app used by 340+ patients to identify triggers, track attack patterns, and get oxygen therapy approved. Available on web, iOS, and Android."
  end

  def faq_meta_description
    "Frequently asked questions about cluster headaches, tracking methods, and how our free app helps patients manage their condition and get treatments approved."
  end

  def charts_meta_description
    "Visualize your cluster headache patterns with interactive charts. Track intensity, duration, triggers, and medication effectiveness over time."
  end

  def native_app_with_tabs?
    return false unless hotwire_native_app?

    # Extract version from user agent
    match = request.user_agent.match(/ClusterHeadacheTracker\/(\d+)\.(\d+)\.(\d+)/)
    return false unless match

    major = match[1].to_i
    minor = match[2].to_i
    build = match[3].to_i

    # Return true for version 1.0.8+ or any version higher than 1.0.x
    return true if major > 1
    return true if major == 1 && minor > 0
    return true if major == 1 && minor == 0 && build >= 8

    false
  end
end
