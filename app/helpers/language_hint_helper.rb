module LanguageHintHelper
  # English public pages always render in English (one indexable URL per language),
  # so visitors whose browser prefers a translated language get a link to it instead.
  def language_hint_locale
    if localized_public_page? && I18n.locale == I18n.default_locale
      accept_language_locale.presence_in(AiVisibleContent::TRANSLATED_LOCALES)
    end
  end

  def language_switcher_url(locale)
    if localized_public_page?
      localized_public_page_url(locale)
    else
      "#{request.path}?#{request.query_parameters.merge("locale" => locale.to_s).to_query}"
    end
  end
end
