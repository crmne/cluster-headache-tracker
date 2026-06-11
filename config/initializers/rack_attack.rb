class Rack::Attack
  # Throttle all requests by IP (60rpm)
  throttle("req/ip", limit: 1000, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Prevent Brute-Force Login Attacks
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  throttle("logins/username", limit: 10, period: 5.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "username").to_s.downcase.presence
    end
  end

  throttle("signups/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/users" && req.post?
  end
end
