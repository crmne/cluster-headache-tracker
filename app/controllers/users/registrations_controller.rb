n# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  private

  def after_sign_up_path_for(resource)
    headache_logs_path
  end

  def after_inactive_sign_up_path_for(resource)
    headache_logs_path
  end
end
