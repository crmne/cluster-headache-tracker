class Users::PreferencesController < ApplicationController
  before_action :authenticate_user!

  def update
    if current_user.update(preferences_params)
      I18n.with_locale(requested_locale) do
        redirect_to settings_path, notice: t(".updated")
      end
    else
      render "users/settings/show", status: :unprocessable_entity
    end
  end

  private

  def preferences_params
    params.expect(user: [ :locale, :time_format ])
  end
end
