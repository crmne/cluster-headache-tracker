# Errors go to our own Bugsink (errors.paolino.me, on our Hetzner server in
# Germany), which takes the Sentry SDK's events. It takes no traces, so
# nothing turns tracing on.
#
# A report names the user by id only (ApplicationController), never by
# username, and never carries headache logs. The SDK's data collection stays
# at its closed defaults, set out here so nobody opens one by accident: no
# request bodies, query strings, cookies, IP addresses, job arguments, or SQL
# values. Don't set send_default_pii: it turns all of that on. Whatever does
# reach a report still goes through the app's filter_parameters.
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"].presence || Rails.application.credentials.sentry_dsn
  config.enabled_environments = %w[ production ]

  config.data_collection.tap do |collection|
    collection.user_info = false
    collection.cookies = false
    collection.http_bodies = []
    collection.url_query_params = false
    collection.http_headers.request = Sentry::DataCollection::KeyValueCollection.new(
      mode: :allow_list, terms: %w[ user-agent accept content-type turbo-frame ]
    )
    collection.http_headers.response = false
    collection.database_query_data = false
    collection.queues = false
  end

  config.before_send = lambda do |event, _hint|
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

    if (request = event.request)
      request.data = filter.filter(request.data) if request.data.is_a?(Hash)
      request.headers = filter.filter(request.headers) if request.headers.is_a?(Hash)
    end
    event.extra = filter.filter(event.extra) if event.extra.present?

    event
  end
end
