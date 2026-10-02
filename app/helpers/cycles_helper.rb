module CyclesHelper
  HEATMAP_LEVEL_CLASSES = [ "bg-base-300", "bg-error/30", "bg-error/50", "bg-error/75", "bg-error" ].freeze

  # Weeks of days for the attack calendar: the last year up to today, or up to
  # the last attack when the logs shown are older than that (a filtered report).
  def attack_calendar_weeks(cycles)
    end_on = calendar_end_on(cycles)
    start_on = (end_on - 52.weeks).beginning_of_week

    (start_on..end_on.end_of_week).each_slice(7).map do |week|
      week.map { |day| day if day <= end_on }
    end
  end

  def attack_calendar_cell_class(count)
    HEATMAP_LEVEL_CLASSES[attack_calendar_level(count)]
  end

  def attack_calendar_cell_title(day, count)
    t("cycles.heatmap.day", date: l(day, format: :long), count: count)
  end

  def attack_calendar_month_label(week)
    if first_of_month = week.compact.find { |day| day.day == 1 }
      l(first_of_month, format: "%b")
    end
  end

  def days_count(days)
    if days
      t("cycles.days", count: days == days.to_i ? days.to_i : days)
    else
      "—"
    end
  end

  private
    def calendar_end_on(cycles)
      if cycles.last_attack_day && cycles.last_attack_day < cycles.today - 1.year
        cycles.last_attack_day
      else
        cycles.today
      end
    end

    def attack_calendar_level(count)
      case count
      when 0 then 0
      when 1 then 1
      when 2 then 2
      when 3..4 then 3
      else 4
      end
    end
end
