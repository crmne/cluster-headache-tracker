# Start and end times are stored as the patient's wall-clock time in a UTC
# column (there is no per-user time zone), so "now" here is the wall-clock time
# in the zone the patient's browser reports (Current.time_zone), and times
# leave the app as instants in that zone.
module User::Attacks
  extend ActiveSupport::Concern

  def current_attack
    headache_logs.ongoing.recent_first.first
  end

  def start_attack(intensity:)
    current_attack || headache_logs.create(start_time: Current.wall_clock_now, intensity: intensity)
  end

  def end_current_attack
    if attack = current_attack
      attack.update!(end_time: Current.wall_clock_now)
      attack
    end
  end

  # The payload the native shells keep for home screen widgets and quick actions.
  # startedAt and lastAttackAt are ISO 8601 instants with the patient's offset:
  # an attack logged at 11:44 in Berlin is "…T11:44:00+02:00".
  def widget_status(time_zone: Current.patient_time_zone)
    ongoing_attack = current_attack
    last_attack = headache_logs.recent_first.first
    today = time_zone.today

    {
      ongoing: ongoing_attack.present?,
      startedAt: instant_in(time_zone, ongoing_attack&.start_time)&.iso8601,
      lastAttackAt: instant_in(time_zone, last_attack&.start_time)&.iso8601,
      attackFreeDays: attack_free_days_since(last_attack, today),
      attacksToday: headache_logs.where(start_time: today.all_day).count,
      locale: I18n.locale.to_s
    }
  end

  private
    def instant_in(time_zone, wall_clock)
      if wall_clock
        time_zone.local(wall_clock.year, wall_clock.month, wall_clock.day, wall_clock.hour, wall_clock.min, wall_clock.sec)
      end
    end

    def attack_free_days_since(last_attack, today)
      if last_attack&.end_time
        [ (today - last_attack.end_time.to_date).to_i, 0 ].max
      else
        0
      end
    end
end
