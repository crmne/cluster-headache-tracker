require "test_helper"

class TranslatedPagesTest < ActionDispatch::IntegrationTest
  test "sample report renders in German" do
    get "/de/sample-report"

    assert_response :success
    assert_select "html[lang=de]"
    assert_select "h1", "Beispielbericht bei Clusterkopfschmerz"
  end

  test "privacy policy renders in Italian with a translation notice" do
    get "/it/privacy-policy"

    assert_response :success
    assert_select "h1", "Informativa sulla privacy di Cluster Headache Tracker"
    assert_select "em a[href='/privacy-policy']", "versione inglese"
  end

  test "English privacy policy has no translation notice" do
    get privacy_policy_url

    assert_response :success
    assert_select "h1", "Privacy Policy for Cluster Headache Tracker"
    assert_no_match "In case of discrepancies", response.body
  end

  test "cluster headache app page renders in Spanish" do
    get "/es/cluster-headache-app"

    assert_response :success
    assert_select "h1", "App para la cefalea en racimos que registra las crisis al instante"
  end

  test "translated pages use translated title and meta description" do
    get "/de/faq"

    assert_response :success
    assert_select "title", I18n.t("seo.pages.faq.title", locale: :de)
    assert_select "meta[name=description][content=?]", I18n.t("seo.pages.faq.description", locale: :de)
  end

  test "translated pages describe themselves in their language without English FAQ structured data" do
    get "/de/faq"

    graph = JSON.parse(css_select("script[type='application/ld+json']").first.text)["@graph"]
    web_page = graph.find { |node| Array(node["@type"]).include?("WebPage") }

    assert_equal "de", web_page["inLanguage"]
    assert_equal "https://clusterheadachetracker.com/de/faq", web_page["url"]
    assert_not graph.any? { |node| node["@type"] == "FAQPage" }
  end

  test "translated pages are indexable" do
    get "/de/faq"

    assert_select "meta[name=robots][content=?]", "index, follow, max-image-preview:large"
  end
end
