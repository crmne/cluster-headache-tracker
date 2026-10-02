# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      if resource.persisted? && helpers.native_app_with_tabs?
        # Ensure the user is properly signed in with remember_me
        sign_in(resource, store: true)
        # For Hotwire Native app with tabs, redirect to recede_historical_location
        redirect_to "/recede_historical_location" and return
      end
    end
  end

  private

  # Someone signing up from a translated page (/de, /it, /es) chose that language explicitly
  def build_resource(hash = {})
    super
    resource.locale ||= params_locale
  end

  def after_sign_up_path_for(resource)
    headache_logs_path(locale: nil)
  end

  def after_inactive_sign_up_path_for(resource)
    headache_logs_path(locale: nil)
  end
end
