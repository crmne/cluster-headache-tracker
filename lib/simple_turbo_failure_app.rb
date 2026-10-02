# Native apps get a 401 instead of a redirect to the sign-in page, so they
# can present their own sign-in flow. Matches native apps the way
# turbo-rails' hotwire_native_app? does: current Hotwire Native clients
# and legacy Turbo Native ones.
class SimpleTurboFailureApp < Devise::FailureApp
  NATIVE_APP_USER_AGENT = /(Turbo|Hotwire) Native/

  def respond
    if request.user_agent.to_s.match?(NATIVE_APP_USER_AGENT)
      http_auth
    else
      super
    end
  end
end
