module ApplicationHelper
  def time_ago_in_words(from_time, format: :long)
    return unless from_time

    distance = (Time.current - from_time).round

    case format
    when :short
      if distance < 1.hour
        pluralize((distance / 60).round, "min")
      elsif distance < 24.hours
        pluralize((distance / 1.hour).round, "hour")
      else
        pluralize((distance / 1.day).round, "day")
      end
    else
      super(from_time)
    end
  end
end
