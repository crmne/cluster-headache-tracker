require "test_helper"

class LanguageChromeTest < ActionDispatch::IntegrationTest
  test "sign in page follows the browser language" do
    get new_user_session_url, headers: { "Accept-Language" => "de-DE,de;q=0.9" }

    assert_select "h2", "Willkommen zurück"
    assert_select "input[type=submit][value=?]", "Anmelden"
  end

  test "failed sign in explains itself in the browser language" do
    post user_session_url, params: { user: { username: "testuser1", password: "wrong" } }, headers: { "Accept-Language" => "de" }

    assert_select "#flash-messages", /Benutzername oder Passwort ist ungültig/
  end

  test "english public pages point browsers that prefer a translation to it" do
    get root_url, headers: { "Accept-Language" => "es-ES,es;q=0.9" }

    assert_select "html[lang=en]"
    assert_select "#language_hint a[href='https://clusterheadachetracker.com/es'][hreflang=es]", "Esta página también está disponible en español"
  end

  test "english public pages show no language hint without a translated preference" do
    get faq_url

    assert_select "#language_hint", count: 0

    get faq_url, headers: { "Accept-Language" => "en-US,de;q=0.5" }

    assert_select "#language_hint", count: 0
  end

  test "translated public pages show no language hint" do
    get root_url(locale: "es"), headers: { "Accept-Language" => "es" }

    assert_select "#language_hint", count: 0
  end

  test "footer links every language version of a public page" do
    get faq_url(locale: "de")

    assert_select "#language_switcher a[hreflang=de][lang=de][aria-current=true][href='https://clusterheadachetracker.com/de/faq']", "Deutsch"
    assert_select "#language_switcher a[hreflang=en][href='https://clusterheadachetracker.com/faq']", "English"
    assert_select "#language_switcher a[hreflang=it][href='https://clusterheadachetracker.com/it/faq']", "Italiano"
    assert_select "footer", /Datenschutzerklärung/
  end

  test "footer switches the language with a parameter on other signed-out pages" do
    get new_user_session_url

    assert_select "#language_switcher a[hreflang=de][href=?]", "/users/sign_in?locale=de"
  end

  test "signed-in users are sent to settings to change their language" do
    sign_in users(:one)

    get headache_logs_url

    assert_select ".navbar a[href='/settings#preferences']", /English/
  end

  test "signed-in users can still switch public page versions" do
    sign_in users(:one)

    get faq_url

    assert_select "#language_switcher a[hreflang]", count: 4
  end

  test "bottom navigation follows the user's language" do
    users(:one).update!(locale: "it")
    sign_in users(:one)

    get headache_logs_url

    assert_select ".dock", /Grafici/
  end
end
