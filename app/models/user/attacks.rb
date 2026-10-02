module User::Attacks
  extend ActiveSupport::Concern

  def current_attack
    headache_logs.ongoing.recent_first.first
  end

  def start_attack(intensity:)
    current_attack || headache_logs.create(start_time: Time.current, intensity: intensity)
  end

  def end_current_attack
    if attack = current_attack
      attack.update!(end_time: Time.current)
      attack
    end
  end

  # The payload the native shells keep for home screen widgets and quick actions.
  def widget_status
    ongoing_attack = current_attack
    last_attack = headache_logs.recent_first.first

    {
      ongoing: ongoing_attack.present?,
      startedAt: ongoing_attack&.start_time&.iso8601,
      lastAttackAt: last_attack&.start_time&.iso8601,
      attackFreeDays: attack_free_days_since(last_attack),
      attacksToday: headache_logs.today.count,
      locale: I18n.locale.to_s
    }
  end

  private
    def attack_free_days_since(last_attack)
      if last_attack&.end_time
        [ (Date.current - last_attack.end_time.to_date).to_i, 0 ].max
      else
        0
      end
    end
end
