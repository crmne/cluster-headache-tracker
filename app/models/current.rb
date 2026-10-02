class Current < ActiveSupport::CurrentAttributes
  attribute :user, :time_zone

  # The patient's calendar day right now. Falls back to the app's zone until
  # the browser has reported its time zone.
  def today
    (time_zone || Time.zone).today
  end
end
