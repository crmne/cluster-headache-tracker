class Users::SessionsController < Devise::SessionsController
  def after_sign_in_path_for(resource)
    headache_logs_path
  end
end
