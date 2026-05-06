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
    assert_equal "index, follow, max-image-preview:large", AiVisibleContent.robots_directive_for("/llms.txt")
    assert_equal "index, follow, max-image-preview:large", AiVisibleContent.robots_directive_for("/ai/page/home.md")
  end

  test "llms text excludes private routes" do
    text = AiVisibleContent.llms_txt

    assert_includes text, "# Cluster Headache Tracker"
    assert_includes text, "Private user dashboards"
    refute_includes text, "/shared_logs/"
    refute_includes text, "/headache_logs/"
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
end
