# A made-up patient for App Store and Google Play review and for store
# screenshots: an episodic cluster period that began about four weeks ago,
# mostly at night, treated with oxygen and sumatriptan on top of a daily
# preventive. Everything is synthetic and relative to today, so resetting the
# account right before a review keeps it current. Resetting replaces every log,
# medication and dose the account has, so never point it at a real person.
class DemoAccount
  PERIOD_DAYS = 26
  NIGHT_HOURS = [ 0, 1, 1, 2, 2, 2, 3, 3, 4, 22, 23 ].freeze
  DAY_HOURS = [ 13, 14, 17 ].freeze
  NOTES = %w[ right_eye_pain woke_tearing_restless severe_slower_relief woke_nasal_congestion pacing_tearing mild_shadow typical_overnight ].freeze

  class NotADemoAccount < StandardError; end

  attr_reader :user

  def self.reset!(username:, password:, ongoing_attack: false)
    new(username:, password:).tap { |account| account.reset!(ongoing_attack:) }
  end

  def initialize(username:, password:)
    @user = User.find_or_initialize_by(username: username)
    @password = password
    @random = Random.new(username.sum)
  end

  def reset!(ongoing_attack: false)
    raise NotADemoAccount, "#{user.username} has logs this class didn't write, so it isn't reset" unless synthetic?

    User.transaction do
      prepare_user
      clear_history
      create_medications
      create_attacks
      create_preventive_doses
      create_ongoing_attack if ongoing_attack
    end
  end

  # An account is only ever reset when every log in it reads like one of ours,
  # so pointing the task at a real person's username wipes nothing.
  def synthetic?
    user.new_record? || user.headache_logs.pluck(:notes).all? { |notes| notes.nil? || demo_notes.include?(notes) }
  end

  private
    attr_reader :random

    def demo_notes
      @demo_notes ||= NOTES.map { |key| I18n.t("headache_log_samples.notes.#{key}", locale: :en) }
    end

    def prepare_user
      user.password = user.password_confirmation = @password
      user.locale = "en"
      user.welcome_seen_at ||= Time.current
      user.last_seen_changelog = ChangelogEntry.current.key
      user.review_prompted_at ||= Time.current
      user.save!
    end

    def clear_history
      user.headache_logs.destroy_all
      user.medication_doses.delete_all
      user.medications.destroy_all
      user.share_tokens.destroy_all
    end

    def create_medications
      @oxygen = user.medications.create!(name: "Oxygen", kind: "oxygen", unit: Medication::OXYGEN_UNIT, default_dose: 15)
      @sumatriptan = user.medications.create!(name: "Sumatriptan injection", kind: "abortive", unit: "mg", default_dose: 6)
      @verapamil = user.medications.create!(name: "Verapamil", kind: "preventive", unit: "mg", default_dose: 240,
        frequency: "once_daily", schedule_note: "With breakfast")
    end

    def create_attacks
      (PERIOD_DAYS - 1).downto(1).each do |days_ago|
        date = Date.current - days_ago

        attacks_on(days_ago).times { |index| create_attack(on: date, at: hour_for(index)) }
      end
    end

    # One or two attacks a night at the height of the period, tapering off.
    def attacks_on(days_ago)
      if days_ago > 18
        random.rand < 0.6 ? 1 : 0
      elsif days_ago > 6
        random.rand < 0.35 ? 2 : 1
      else
        random.rand < 0.7 ? 1 : 0
      end
    end

    def hour_for(index)
      index.zero? ? NIGHT_HOURS.sample(random: random) : (random.rand < 0.5 ? DAY_HOURS.sample(random: random) : 4)
    end

    def create_attack(on:, at:)
      start_time = Time.zone.local(on.year, on.month, on.day, at, random.rand(60))
      intensity = [ 5, 6, 7, 7, 8, 8, 8, 9, 9, 10 ].sample(random: random)
      minutes = random.rand(25..95)

      log = user.headache_logs.create!(
        start_time: start_time,
        end_time: start_time + minutes.minutes,
        intensity: intensity,
        triggers: trigger_for(at),
        notes: I18n.t("headache_log_samples.notes.#{NOTES.sample(random: random)}", locale: :en)
      )
      treat(log, intensity:, minutes:)
    end

    def trigger_for(hour)
      key = if hour.between?(0, 5) then "sleep_disruption"
      elsif random.rand < 0.3 then "alcohol"
      else "none_noted"
      end

      I18n.t("headache_log_samples.triggers.#{key}", locale: :en)
    end

    def treat(log, intensity:, minutes:)
      log.medication_doses.create!(user: user, medication: @oxygen, amount: [ 12, 15 ].sample(random: random),
        taken_at: log.start_time + 4.minutes, duration_minutes: [ 15, 20 ].sample(random: random),
        minutes_to_relief: [ minutes - 5, 10 ].max, effectiveness: "helped")

      if intensity >= 9
        log.medication_doses.create!(user: user, medication: @sumatriptan, amount: 6,
          taken_at: log.start_time + 10.minutes, minutes_to_relief: 12,
          effectiveness: random.rand < 0.85 ? "helped" : "no_effect")
      end
    end

    def create_preventive_doses
      (PERIOD_DAYS - 12).downto(1).each do |days_ago|
        date = Date.current - days_ago
        next if random.rand < 0.08

        user.medication_doses.create!(medication: @verapamil, amount: 240,
          taken_at: Time.zone.local(date.year, date.month, date.day, 8, random.rand(30)))
      end
    end

    def create_ongoing_attack
      user.headache_logs.create!(start_time: Current.wall_clock_now - 14.minutes, intensity: 8,
        triggers: I18n.t("headache_log_samples.triggers.sleep_disruption", locale: :en))
    end
end
