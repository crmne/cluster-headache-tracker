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
   "Cluster Headache Tracker"
  end

  def app_short_description
    "Free, Private Tool for Tracking Cluster Headaches"
  end

  def app_description
    "Track and manage your cluster headaches with our free, privacy-focused tool. Log symptoms, analyze patterns, and share reports with your doctor."
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
end
