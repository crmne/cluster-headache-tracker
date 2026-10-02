require "test_helper"

# The native apps download these path configurations at launch; a mistake
# here changes navigation in every installed app without a release.
class PathConfigurationsTest < ActiveSupport::TestCase
  CONFIGURATIONS = %w[ android_v1 android_v2 ios_v1 ios_v2 ].freeze
  FORMS = %w[ /headache_logs/new /headache_logs/new?quick=1 /headache_logs/1/edit /current_attack
    /medications/new /medications/1/edit /medication_doses/new /medication_doses/1/edit ].freeze
  TABS = %w[ /headache_logs /charts /settings /feedback ].freeze

  test "every configuration is valid JSON with rules" do
    CONFIGURATIONS.each do |name|
      assert_kind_of Array, configuration(name)["rules"], name
    end
  end

  test "forms open as modals in every configuration" do
    CONFIGURATIONS.each do |name|
      FORMS.each do |path|
        assert_equal "modal", properties_for(name, path)["context"], "#{name} #{path}"
      end
    end
  end

  test "v2 configurations start with the catch-all rule so later rules win" do
    %w[ android_v2 ios_v2 ].each do |name|
      assert_equal [ ".*" ], configuration(name)["rules"].first["patterns"], name
    end
  end

  test "v2 forms don't pull to refresh, other pages do" do
    %w[ android_v2 ios_v2 ].each do |name|
      FORMS.each do |path|
        assert_equal false, properties_for(name, path)["pull_to_refresh_enabled"], "#{name} #{path}"
      end

      assert_equal true, properties_for(name, "/medications")["pull_to_refresh_enabled"], name
      assert_equal true, properties_for(name, "/timeline")["pull_to_refresh_enabled"], name
    end
  end

  test "v2 tabs replace the root in the default context" do
    %w[ android_v2 ios_v2 ].each do |name|
      TABS.each do |path|
        assert_equal "default", properties_for(name, path)["context"], "#{name} #{path}"
      end
    end

    TABS.each do |path|
      assert_equal "replace", properties_for("android_v2", path)["presentation"], path
    end
  end

  test "iOS form sheets use the snake_case modal style Hotwire Native expects" do
    FORMS.each do |path|
      assert_equal "page_sheet", properties_for("ios_v2", path)["modal_style"], path
    end

    assert_equal "large", properties_for("ios_v2", "/users/sign_in")["modal_style"]
  end

  private
    def configuration(name)
      JSON.parse(Rails.public_path.join("configurations/#{name}.json").read)
    end

    # Hotwire Native merges the properties of every matching rule in order.
    def properties_for(name, path)
      configuration(name)["rules"].each_with_object({}) do |rule, properties|
        if rule["patterns"].any? { |pattern| Regexp.new(pattern).match?(path) }
          properties.merge!(rule["properties"])
        end
      end
    end
end
