require "test_helper"

class AiVisibleContentControllerTest < ActionDispatch::IntegrationTest
  test "serves llms text" do
    get "/llms.txt"

    assert_response :success
    assert_includes @response.media_type, "text/plain"
    assert_includes @response.body, "# Cluster Headache Tracker"
    assert_includes @response.body, "Structured product profile"
    refute_includes @response.body, "/shared_logs/"
  end

  test "serves full llms text" do
    get "/llms-full.txt"

    assert_response :success
    assert_includes @response.body, "## Public Page Details"
    assert_includes @response.body, "# Cluster Headache Tracker for Neurologists"
  end

  test "serves structured llm json" do
    get "/llm.json"

    assert_response :success
    data = JSON.parse(@response.body)

    assert_equal "Cluster Headache Tracker", data["name"]
    assert_equal false, data.dig("privacy", "email_required")
    assert_includes data["features"], "One-tap cluster headache attack logging"
  end

  test "serves entity map" do
    get "/entity-map.json"

    assert_response :success
    data = JSON.parse(@response.body)

    assert_equal "Cluster Headache Tracker", data.dig("primary_entity", "name")
    assert data["entities"].any? { |entity| entity["name"] == "Cluster headaches" }
  end

  test "serves page markdown mirror" do
    get "/ai/page/neurologist.md"

    assert_response :success
    assert_equal "text/markdown", @response.media_type
    assert_includes @response.body, "# Cluster Headache Tracker for Neurologists"
    assert_includes @response.body, "temporary share link"
  end

  test "serves topic json resource" do
    get "/ai/topic/cluster-headaches.json"

    assert_response :success
    data = JSON.parse(@response.body)

    assert_equal "Thing", data["@type"]
    assert_equal "Cluster headaches", data["name"]
    assert_includes data["mentions"], "https://clusterheadachetracker.com/"
  end

  test "serves yaml resource" do
    get "/ai/entity/cluster-headache-tracker.yml"

    assert_response :success
    assert_equal "application/x-yaml", @response.media_type
    assert_includes @response.body, "Cluster Headache Tracker"
  end

  test "returns not found for unknown resource" do
    get "/ai/topic/not-real.json"

    assert_response :not_found
  end
end
