require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get home_index_url
    assert_response :success
  end

  test "home page exposes ai resource links and json ld" do
    get root_url

    assert_response :success
    assert_select "link[rel='alternate'][href='https://clusterheadachetracker.com/llms.txt']"
    assert_select "link[rel='alternate'][href='https://clusterheadachetracker.com/ai/page/home.md']"
    assert_select "script[type='application/ld+json']", text: /Cluster Headache Tracker/
  end

  test "public static pages are reachable" do
    get faq_url
    assert_response :success

    get neurologist_url
    assert_response :success
  end
end
