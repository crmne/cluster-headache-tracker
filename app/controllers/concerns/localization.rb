module Localization
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
    before_action :set_current_user
  end

  private
    def switch_locale(&action)
      I18n.with_locale(requested_locale, &action)
    end

    # A signed-in user's saved language wins, then an explicit ?locale=,
    # then the browser's (or native shell's) Accept-Language header.
    def requested_locale
      user_locale || params_locale || accept_language_locale || I18n.default_locale
    end

    def user_locale
      current_user.locale if user_signed_in?
    end

    def params_locale
      params[:locale].presence_in(available_locale_names)
    end

    def accept_language_locale
      accepted_languages.find { |language| available_locale_names.include?(language) }
    end

    def accepted_languages
      ranges = request.headers["Accept-Language"].to_s.split(",").each_with_index.filter_map do |range, position|
        tag, *parameters = range.split(";").map(&:strip)
        quality = parameters.find { |parameter| parameter.start_with?("q=") }&.delete_prefix("q=")&.to_f || 1.0

        [ tag.split("-").first.downcase, quality, position ] if tag.present? && quality.positive?
      end

      ranges.sort_by { |_, quality, position| [ -quality, position ] }.map(&:first)
    end

    def available_locale_names
      I18n.available_locales.map(&:to_s)
    end

    # Carry an explicitly chosen language from page to page. English is the
    # unprefixed default, so it never needs carrying (and /en/... isn't a route).
    def default_url_options
      { locale: params_locale.presence_in(prefixed_locale_names) }
    end

    def prefixed_locale_names
      available_locale_names.excluding(I18n.default_locale.to_s)
    end

    def set_current_user
      Current.user = current_user if user_signed_in?
    end
end
