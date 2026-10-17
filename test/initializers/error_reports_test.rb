require "test_helper"

class ErrorReportsTest < ActiveSupport::TestCase
  test "reports carry the request, its body and headers, without secrets, auth headers, cookies or IP addresses" do
    HeadacheLog.filter_attributes # encrypted columns join filter_parameters when their model loads
    event = report_for Rack::MockRequest.env_for(
      "https://clusterheadachetracker.com/headache_logs?page=2&token=abc",
      method: "POST",
      params: { headache_log: { intensity: "8", notes: "Woke me at 3am" }, user: { password: "hunter2" } },
      "HTTP_USER_AGENT" => "Cluster Headache Tracker iOS",
      "HTTP_AUTHORIZATION" => "Bearer secret",
      "HTTP_COOKIE" => "_session=abc",
      "HTTP_X_FORWARDED_FOR" => "203.0.113.7",
      "REMOTE_ADDR" => "203.0.113.7"
    )
    request = event.request

    assert_equal "https://clusterheadachetracker.com/headache_logs", request.url
    assert_equal "2", request.query_string["page"]
    assert_equal "[FILTERED]", request.query_string["token"].upcase
    assert_equal "8", request.data.dig("headache_log", "intensity")
    assert_equal "[FILTERED]", request.data.dig("headache_log", "notes")
    assert_equal "[FILTERED]", request.data.dig("user", "password").upcase
    assert_equal "Cluster Headache Tracker iOS", request.headers["User-Agent"]
    assert_includes [ nil, "[Filtered]" ], request.headers["Authorization"]
    assert_includes [ nil, "[Filtered]" ], request.headers["Cookie"]
    assert_includes [ nil, "[Filtered]" ], request.headers["X-Forwarded-For"]
    assert_empty request.cookies.to_h
    assert_not_includes request.env.to_h.keys, "REMOTE_ADDR"
    assert_not event.user.key?(:ip_address)
    assert_not_includes event.to_h.to_json, "203.0.113.7"
  end

  test "reports keep exception messages, the user and breadcrumbs" do
    assert_includes Sentry.configuration.breadcrumbs_logger, :active_support_logger
    assert Sentry.configuration.data_collection.user_info
    assert_not Sentry.configuration.send_default_pii

    event = Sentry.configuration.before_send.call(
      Sentry::ErrorEvent.new(configuration: Sentry.configuration).tap do |e|
        e.user = { id: 1, username: "carmine" }
        e.add_exception_interface(RuntimeError.new("Couldn't save log 42"), mechanism: Sentry::Mechanism.new)
      end, {}
    )

    assert_equal({ id: 1, username: "carmine" }, event.user)
    assert_includes event.to_h.to_json, "Couldn't save log 42"
  end

  private
    def report_for(env)
      event = Sentry::ErrorEvent.new(configuration: Sentry.configuration)
      event.rack_env = env
      Sentry.configuration.before_send.call(event, {})
    end
end
