class SimpleTurboFailureApp < Devise::FailureApp
  def respond
    if request.user_agent.to_s.match?(/(Turbo|Hotwire) Native/)
      http_auth
    else
      super
    end
  end
end
