class Users::SessionsController < Devise::SessionsController
  include ApplicationHelper

  def create
    super do |resource|
      if resource.persisted? && helpers.native_app_with_tabs?
        # For Hotwire Native app with tabs, redirect to recede_historical_location
        redirect_to "/recede_historical_location" and return
      end
    end
  end

  def after_sign_in_path_for(resource)
    headache_logs_path
  end

  def after_sign_out_path_for(scope)
    # For Hotwire Native app with tabs, go to headache_logs to trigger auth flow
    if helpers.native_app_with_tabs?
      headache_logs_path
    else
      root_path
    end
  end
end
