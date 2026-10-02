require "test_helper"

class LocalizationTest < ActionDispatch::IntegrationTest
  test "defaults to English" do
    get new_user_session_url

    assert_select "html[lang=en]"
  end

  test "follows the Accept-Language header" do
    get new_user_session_url, headers: { "Accept-Language" => "de-DE,de;q=0.9,en;q=0.8" }

    assert_select "html[lang=de]"
  end

  test "picks the most preferred supported language" do
    get new_user_session_url, headers: { "Accept-Language" => "fr-FR, en;q=0.5, es;q=0.8" }

    assert_select "html[lang=es]"
  end

  test "ignores unsupported languages" do
    get new_user_session_url, headers: { "Accept-Language" => "fr-FR,fr;q=0.9" }

    assert_select "html[lang=en]"
  end

  test "an explicit locale parameter wins over Accept-Language" do
    get new_user_session_url(locale: "it"), headers: { "Accept-Language" => "de" }

    assert_select "html[lang=it]"
  end

  test "ignores unknown locale parameters" do
    get new_user_session_url(locale: "xx")

    assert_select "html[lang=en]"
  end

  test "a signed-in user's saved language wins" do
    users(:one).update!(locale: "es")
    sign_in users(:one)

    get settings_url(locale: "it"), headers: { "Accept-Language" => "de" }

    assert_select "html[lang=es]"
  end

  test "signed-in users without a saved language follow their device" do
    sign_in users(:one)

    get settings_url, headers: { "Accept-Language" => "it-IT" }

    assert_select "html[lang=it]"
  end

  test "public pages use the language in their URL, not Accept-Language" do
    get faq_url, headers: { "Accept-Language" => "de" }
    assert_select "html[lang=en]"

    get faq_url(locale: "de")
    assert_select "html[lang=de]"
    assert_equal "/de/faq", path
  end

  test "public pages link to their translations" do
    get faq_url(locale: "it")

    assert_select "link[rel=canonical][href='https://clusterheadachetracker.com/it/faq']"
    assert_select "link[rel=alternate][hreflang=en][href='https://clusterheadachetracker.com/faq']"
    assert_select "link[rel=alternate][hreflang=de][href='https://clusterheadachetracker.com/de/faq']"
    assert_select "link[rel=alternate][hreflang=it][href='https://clusterheadachetracker.com/it/faq']"
    assert_select "link[rel=alternate][hreflang=es][href='https://clusterheadachetracker.com/es/faq']"
    assert_select "link[rel=alternate][hreflang=x-default][href='https://clusterheadachetracker.com/faq']"
    assert_select "meta[name=robots][content^=index]"
  end

  test "the translated home page lives under the language prefix" do
    get root_url(locale: "es")

    assert_response :success
    assert_select "html[lang=es]"
    assert_select "link[rel=alternate][hreflang=x-default][href='https://clusterheadachetracker.com/']"
  end

  test "private pages have no language alternates" do
    sign_in users(:one)

    get settings_url

    assert_select "link[hreflang]", count: 0
  end

  test "English is not a prefixed language" do
    get "/en/faq"

    assert_response :not_found
  end

  test "renders the current language's JavaScript translations and clock" do
    users(:one).update!(locale: "de")
    sign_in users(:one)

    get settings_url

    assert_select "body[data-locale=de][data-hour-cycle=h23]"
    assert_select "script#translations[type='application/json']"
  end
end
