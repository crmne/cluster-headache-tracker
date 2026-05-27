require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get home_index_url
    assert_response :success
  end

  test "home page exposes ai resource links and json ld" do
    get root_url

    assert_response :success
    assert_select "link[rel='canonical'][href='https://clusterheadachetracker.com/']"
    assert_select "link[rel='alternate'][href='https://clusterheadachetracker.com/llms.txt']"
    assert_select "link[rel='alternate'][href='https://clusterheadachetracker.com/ai/page/home.md']"
    assert_select "script[type='application/ld+json']", text: /Cluster Headache Tracker/
  end

  test "www host redirects to apex canonical host" do
    host! "www.clusterheadachetracker.com"

    get "/not-a-real-page?utm_source=search"

    assert_response :moved_permanently
    assert_equal "https://clusterheadachetracker.com/not-a-real-page?utm_source=search", response.location
  end

  test "public static pages are reachable" do
    public_urls = [
      faq_url,
      neurologist_url,
      cluster_headache_diary_url,
      cluster_headache_diary_template_url,
      headache_diary_for_neurologist_url,
      cluster_headache_oxygen_documentation_url,
      sample_report_url,
      cluster_headache_app_url,
      open_source_headache_tracker_url
    ]

    public_urls.each do |url|
      get url

      assert_response :success
      assert_equal "index, follow, max-image-preview:large", response.headers["X-Robots-Tag"]
    end
  end

  test "home page uses explicit tracker and diary positioning" do
    get root_url

    assert_response :success
    assert_select "title", text: "Cluster Headache Tracker & Diary | Free, Private, Doctor-Ready Reports"
    assert_select "h1", text: /Wrestling with cluster headaches\?/
    assert_select "a[href='#{cluster_headache_diary_path}']", text: /Cluster Headache Diary|Diary/
  end

  test "sample report uses real report partials with demo data" do
    get sample_report_url

    assert_response :success
    assert_select "h1", text: "Sample Cluster Headache Report"
    assert_select "h2", text: "Analysis"
    assert_select "h2", text: "Detailed Log Entries"
    assert_select "canvas#intensityChart"
    assert_select "table tbody tr", minimum: 10
  end
end
