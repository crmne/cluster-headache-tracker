# Errors go to our own Bugsink (errors.paolino.me, on our Hetzner server in
# Germany), which takes the Sentry SDK's events. It takes no traces, so
# nothing turns tracing on.
#
# Reports are full, so a problem can be fixed from the report alone: the
# exception and its message, the request's URL, query, body, and headers, the
# breadcrumbs leading up to it, the user's id and username
# (ApplicationController), and tags. That can include health data a person
# was saving when the request failed; the privacy policy says so.
#
# Kept out: passwords, tokens, keys, and anything else filter_parameters
# names (in the query and breadcrumbs by sentry-rails, in the body, headers,
# and extras by before_send below), the Authorization and Cookie headers,
# cookies, and IP addresses, which the privacy policy promises reports never
# carry. Never set send_default_pii: data_collection replaces it.
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"].presence || Rails.application.credentials.sentry_dsn
  config.enabled_environments = %w[ production ]
  config.breadcrumbs_logger = %i[ active_support_logger http_logger ]

  config.data_collection.tap do |collection|
    collection.user_info = true
    collection.cookies = false
    collection.http_bodies = %i[ incoming_request ]
    collection.url_query_params = true
    collection.http_headers.request = Sentry::DataCollection::KeyValueCollection.new(
      mode: :deny_list, terms: %w[ authorization cookie ] + Sentry::DataCollection::PII_HEADER_SNIPPETS
    )
    collection.http_headers.response = false
  end

  config.before_send = lambda do |event, _hint|
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

    if (request = event.request)
      request.data = filter.filter(request.data) if request.data.is_a?(Hash)
      request.headers = filter.filter(request.headers) if request.headers.is_a?(Hash)
      request.env = request.env.except("REMOTE_ADDR") if request.env.is_a?(Hash)
    end
    event.user = event.user.except(:ip_address) if event.user.present?
    event.extra = filter.filter(event.extra) if event.extra.present?

    event
  end
end
