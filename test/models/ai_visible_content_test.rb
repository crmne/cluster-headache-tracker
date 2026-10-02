require "test_helper"

class AiVisibleContentTest < ActiveSupport::TestCase
  test "public pages all have descriptions and topics" do
    AiVisibleContent::PUBLIC_PAGES.each_value do |page|
      assert page[:title].present?, "missing title for #{page[:slug]}"
      assert page[:description].present?, "missing description for #{page[:slug]}"
      assert page[:topics].present?, "missing topics for #{page[:slug]}"
    end
  end

  test "private app paths are not indexable" do
    assert_equal "noindex, nofollow", AiVisibleContent.robots_directive_for("/headache_logs")
    assert_equal "noindex, nofollow", AiVisibleContent.robots_directive_for("/shared_logs/token")
  end

  test "public pages and ai resources are indexable" do
    assert_equal "index, follow, max-image-preview:large", AiVisibleContent.robots_directive_for("/")
    assert_equal "index, follow, max-image-preview:large", AiVisibleContent.robots_directive_for("/cluster-headache-diary")
    assert_equal "index, follow, max-image-preview:large", AiVisibleContent.robots_directive_for("/sample-report")
    assert_equal "index, follow, max-image-preview:large", AiVisibleContent.robots_directive_for("/llms.txt")
    assert_equal "index, follow, max-image-preview:large", AiVisibleContent.robots_directive_for("/ai/page/home.md")
  end

  test "new landing pages are exposed as ai page resources" do
    markdown = AiVisibleContent.page_markdown("cluster-headache-diary")

    assert_includes markdown, "# Free Cluster Headache Diary"
    assert_includes markdown, "KIP-style intensity"

    resource = AiVisibleContent.resource("page", "sample-report")

    assert_equal "Sample Cluster Headache Report", resource["name"]
    assert_includes resource["text"], "fictional"
  end

  test "json ld graph uses stable entity ids" do
    graph = AiVisibleContent.json_ld_for(
      path: "/faq",
      logo_url: "https://example.com/logo.png",
      android_apk_url: "https://example.com/app.apk"
    )

    ids = graph["@graph"].filter_map { |node| node["@id"] }

    assert_includes ids, "https://clusterheadachetracker.com/#cluster-headache-tracker"
    assert_includes ids, "https://clusterheadachetracker.com/#carmine-paolino"
    assert_includes ids, "https://clusterheadachetracker.com/faq#faq"
  end

  test "home page video json ld includes required google fields" do
    graph = AiVisibleContent.json_ld_for(
      path: "/",
      logo_url: "https://example.com/logo.png",
      android_apk_url: "https://example.com/app.apk"
    )

    video = graph["@graph"].find { |node| node["@type"] == "VideoObject" }

    assert_equal "Cluster Headache Tracker Demo", video["name"]
    assert_equal "2024-12-21T13:39:46-08:00", video["uploadDate"]
    assert_equal "https://i.ytimg.com/vi/4HlsqANZdv8/maxresdefault.jpg", video["thumbnailUrl"]
    assert_equal "https://www.youtube.com/embed/4HlsqANZdv8", video["embedUrl"]
  end

  test "translated pages share their English page's entry" do
    assert_equal AiVisibleContent.page_for_path("/faq"), AiVisibleContent.page_for_path("/de/faq")
    assert_equal AiVisibleContent.page_for_path("/"), AiVisibleContent.page_for_path("/es")
    assert_nil AiVisibleContent.page_for_path("/design")
    assert_equal "index, follow, max-image-preview:large", AiVisibleContent.robots_directive_for("/it/sample-report")
  end

  test "localized paths" do
    assert_equal "/faq", AiVisibleContent.localized_path("/faq", :en)
    assert_equal "/de/faq", AiVisibleContent.localized_path("/faq", :de)
    assert_equal "/it", AiVisibleContent.localized_path("/", :it)
  end

  test "translated json ld describes the translated page without English-only FAQ data" do
    graph = AiVisibleContent.json_ld_for(
      path: "/de/faq",
      logo_url: "https://example.com/logo.png",
      android_apk_url: "https://example.com/app.apk",
      translation: { locale: :de, title: "Häufige Fragen", description: "Antworten" }
    )

    web_page = graph["@graph"].find { |node| node["@id"] == "https://clusterheadachetracker.com/de/faq#webpage" }

    assert_equal "de", web_page["inLanguage"]
    assert_equal "Häufige Fragen", web_page["name"]
    assert_equal({ "@id" => "https://clusterheadachetracker.com/faq#webpage" }, web_page["translationOfWork"])
    assert_nil graph["@graph"].find { |node| node["@type"] == "FAQPage" }
  end
end
