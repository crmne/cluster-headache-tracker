module CurrentTimeZone
  extend ActiveSupport::Concern

  included do
    before_action :set_current_time_zone
  end

  private
    def set_current_time_zone
      Current.time_zone = ActiveSupport::TimeZone[cookies[:time_zone].to_s]
    end
end
