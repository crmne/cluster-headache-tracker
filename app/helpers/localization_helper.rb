module LocalizationHelper
  # Formats a time with the signed-in user's 12h/24h preference, falling back
  # to the convention of the current language (12h for English, 24h otherwise).
  #
  #   <%= format_time log.start_time %>                  # 7:05 PM / 19:05
  #   <%= format_time log.start_time, :day_and_time %>   # Oct 2, 7:05 PM / 2. Okt., 19:05
  #
  # Available formats live under time.formats.*_12h / *_24h in config/locales/formats.*.yml
  def format_time(time, format = :time)
    l(time, format: :"#{format}_#{current_time_format}")
  end

  def current_time_format
    Current.user&.time_format_or_default || User.default_time_format_for(I18n.locale)
  end

  def current_hour_cycle
    current_time_format == "12h" ? "h12" : "h23"
  end

  def language_name(locale)
    t("languages.#{locale}", locale: locale)
  end

  # Translations the Stimulus controllers need, keyed under js.* and read by app/javascript/i18n.js
  def javascript_translations_tag
    tag.script(json_escape(t("js", default: {}).to_json).html_safe, type: "application/json", id: "translations")
  end

  def public_page_language_alternate_tags
    if localized_public_page?
      tags = I18n.available_locales.map do |locale|
        tag.link(rel: "alternate", hreflang: locale, href: localized_public_page_url(locale))
      end
      tags << tag.link(rel: "alternate", hreflang: "x-default", href: localized_public_page_url(I18n.default_locale))

      safe_join(tags, "\n")
    end
  end

  def localized_public_page?
    controller_name == "home" && current_ai_visible_page.present?
  end

  def localized_public_page_url(locale)
    AiVisibleContent.absolute_url(AiVisibleContent.localized_path(current_ai_visible_page[:path], locale))
  end

  def translated_public_page?
    localized_public_page? && I18n.locale != I18n.default_locale
  end

  # English public page titles and descriptions come from config/ai_visible_pages.yml,
  # their translations from config/locales/seo.*.yml
  def translated_public_page_title
    t("seo.pages.#{current_ai_visible_page[:slug]}.title")
  end

  def translated_public_page_description
    t("seo.pages.#{current_ai_visible_page[:slug]}.description")
  end

  def translated_public_page_metadata
    { locale: I18n.locale, title: translated_public_page_title, description: translated_public_page_description }
  end

  def open_graph_locale
    t("open_graph_locale")
  end
end
