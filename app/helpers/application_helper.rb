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
    "Cluster Headache Tracker - Free Tracking by a Fellow Sufferer"
  end

  def app_short_description
    "Private, Free Cluster Headache Tracking That Actually Helps"
  end

  def app_description
    "Built by a cluster headache sufferer who needed better tracking. Log attacks in seconds, spot real patterns, get reports that helped others get oxygen approved. Free forever, no email required, your data stays private."
  end

  def page_title
    if hotwire_native_app? && content_for(:title)
      # For native apps, only show the page title
      content_for(:title)
    elsif content_for(:title)
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
    "I built this free cluster headache tracker because I needed it. Join 340+ sufferers who finally have data that helps. Log attacks fast, see patterns clearly, share with doctors. No email, no tracking, just help."
  end

  def faq_meta_description
    "Real answers about cluster headaches from someone who gets them. Learn why tracking matters, how this free tool helps, and what actually works for getting treatment approved."
  end

  def charts_meta_description
    "See your cluster headache patterns like never before. Charts that show real cycles, trigger correlations, and treatment effectiveness. Data that helps you and your doctor make better decisions."
  end

  def native_app_with_tabs?
    return false unless hotwire_native_app?

    version_parts = native_app_version_parts
    return false unless version_parts

    major, minor, build = version_parts

    # Return true for version 1.0.8+ or any version higher than 1.0.x
    return true if major > 1
    return true if major == 1 && minor > 0
    return true if major == 1 && minor == 0 && build >= 8

    false
  end

  def android_native_app?
    current_mobile_app_platform == "android"
  end

  def ios_native_app?
    current_mobile_app_platform == "ios"
  end

  def android_apk_url
    if snapshot = MobileReleaseSnapshot.for_platform("android")
      snapshot.release_url.presence || AppConstants::ANDROID_APK_URL
    else
      AppConstants::ANDROID_APK_URL
    end
  end

  def current_mobile_app_platform
    return unless hotwire_native_app?

    request.headers["X-App-Platform"].presence&.downcase || platform_from_user_agent
  end

  def native_app_version
    request.headers["X-App-Version"].presence || version_from_user_agent
  end

  def current_mobile_release_snapshot
    MobileReleaseSnapshot.for_platform(current_mobile_app_platform)
  end

  def current_mobile_app_platform_name
    if current_mobile_app_platform == "android"
      "Android"
    elsif current_mobile_app_platform == "ios"
      "iOS"
    end
  end

  def mobile_app_update_available?
    if snapshot = current_mobile_release_snapshot
      snapshot.update_available_for?(native_app_version)
    else
      false
    end
  end

  def mobile_app_update_required?
    if snapshot = current_mobile_release_snapshot
      snapshot.update_required_for?(native_app_version)
    else
      false
    end
  end

  def show_mobile_app_update_modal?
    if snapshot = current_mobile_release_snapshot
      snapshot.release_url.present? && (mobile_app_update_required? || mobile_app_update_available?)
    else
      false
    end
  end

  private
    def platform_from_user_agent
      user_agent = request.user_agent.to_s

      if user_agent.include?("Android")
        "android"
      elsif user_agent.include?("iPhone") || user_agent.include?("iPad") || user_agent.include?("iOS")
        "ios"
      end
    end

    def version_from_user_agent
      user_agent = request.user_agent.to_s

      if match = user_agent.match(/ClusterHeadacheTracker;\s*platform=\w+;\s*version=([0-9.]+);\s*build=[^;]+;?/)
        match[1]
      elsif match = user_agent.match(/ClusterHeadacheTracker\/([0-9]+\.[0-9]+\.[0-9]+)(?:\.[0-9]+)?;/)
        match[1]
      end
    end

    def native_app_version_parts
      return nil unless hotwire_native_app?

      if version = native_app_version
        version.split(".").map(&:to_i)
      end
    end
end
