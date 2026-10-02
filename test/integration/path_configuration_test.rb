require "test_helper"

# Hotwire Native applies every rule whose pattern matches a path, in order, so later
# rules override earlier ones. These tests resolve paths the same way.
class PathConfigurationTest < ActionDispatch::IntegrationTest
  %w[ ios_v2 android_v2 ].each do |configuration|
    test "#{configuration} opens log forms and the current attack as modals without pull to refresh" do
      [ "/headache_logs/new", "/headache_logs/12/edit", "/current_attack" ].each do |path|
        properties = resolve(configuration, path)

        assert_equal "modal", properties["context"], path
        assert_equal false, properties["pull_to_refresh_enabled"], path
      end
    end

    test "#{configuration} handles refresh and resume historical locations" do
      assert_equal({ "presentation" => "refresh", "historical_location" => true }, resolve(configuration, "/refresh_historical_location").slice("presentation", "historical_location"))
      assert_equal({ "presentation" => "none", "historical_location" => true }, resolve(configuration, "/resume_historical_location").slice("presentation", "historical_location"))
    end

    test "#{configuration} keeps tab roots in the default context" do
      [ "/headache_logs", "/charts", "/settings", "/feedback" ].each do |path|
        assert_equal "default", resolve(configuration, path)["context"], path
      end
    end

    test "#{configuration} is served" do
      get "/configurations/#{configuration}.json"

      assert_response :success
    end
  end

  test "android_v2 renders modals in the modal fragment" do
    assert_equal "hotwire://fragment/web/modal", resolve("android_v2", "/headache_logs/new")["uri"]
    assert_equal "hotwire://fragment/web/modal", resolve("android_v2", "/current_attack")["uri"]
    assert_equal "hotwire://fragment/web", resolve("android_v2", "/charts")["uri"]
  end

  test "ios_v2 presents log forms and the current attack as page sheets" do
    assert_equal "page_sheet", resolve("ios_v2", "/headache_logs/new")["modal_style"]
    assert_equal "page_sheet", resolve("ios_v2", "/current_attack")["modal_style"]
  end

  private
    def resolve(configuration, path)
      rules(configuration).select { |rule| rule["patterns"].any? { |pattern| path.match?(Regexp.new(pattern)) } }
        .reduce({}) { |properties, rule| properties.merge(rule["properties"]) }
    end

    def rules(configuration)
      JSON.parse(Rails.root.join("public/configurations/#{configuration}.json").read)["rules"]
    end
end
