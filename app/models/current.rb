class Current < ActiveSupport::CurrentAttributes
  attribute :user, :time_zone

  # The patient's calendar day right now. Falls back to the app's zone until
  # the browser has reported its time zone.
  def today
    patient_time_zone.today
  end

  # Logged times are stored as the patient's wall clock in the app's zone, so
  # "now" for a new log or dose is the patient's local time in that zone.
  def wall_clock_now
    now = patient_time_zone.now
    Time.zone.local(now.year, now.month, now.day, now.hour, now.min, now.sec)
  end

  def patient_time_zone
    time_zone || Time.zone
  end
end
