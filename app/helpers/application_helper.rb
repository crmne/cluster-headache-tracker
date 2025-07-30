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

  def android_apk_url
    "/cluster-headache-tracker.apk?v=#{AppConstants::ANDROID_APK_VERSION}"
  end

  def native_app_version
    parts = native_app_version_parts
    return nil unless parts

    parts.join(".")
  end

  def android_app_needs_update?
    return false unless hotwire_native_app? && request.user_agent.include?("Android")

    current_parts = native_app_version_parts
    return false unless current_parts

    # Compare versions
    latest_parts = AppConstants::ANDROID_APK_VERSION.split(".").map(&:to_i)

    # Compare major.minor.patch
    current_parts.each_with_index do |part, index|
      return true if part < latest_parts[index]
      return false if part > latest_parts[index]
    end

    false
  end

  private

  def native_app_version_parts
    return nil unless hotwire_native_app?

    match = request.user_agent.match(/ClusterHeadacheTracker\/(\d+)\.(\d+)\.(\d+)/)
    return nil unless match

    [ match[1].to_i, match[2].to_i, match[3].to_i ]
  end
end
