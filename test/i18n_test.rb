require "test_helper"
require "i18n/tasks"

class I18nTest < ActiveSupport::TestCase
  setup do
    @i18n = I18n::Tasks::BaseTask.new
  end

  test "every key used in the app is translated in every language" do
    missing_keys = @i18n.missing_keys

    assert_empty missing_keys, "Missing #{missing_keys.leaves.count} i18n keys, run `bundle exec i18n-tasks missing` to show them"
  end

  test "every translation is used" do
    unused_keys = @i18n.unused_keys

    assert_empty unused_keys, "#{unused_keys.leaves.count} unused i18n keys, run `bundle exec i18n-tasks unused` to show them"
  end

  test "translations interpolate the same variables as English" do
    inconsistent_interpolations = @i18n.inconsistent_interpolations

    assert_empty inconsistent_interpolations, "#{inconsistent_interpolations.leaves.count} i18n keys have inconsistent interpolations, run `bundle exec i18n-tasks check-consistent-interpolations` to show them"
  end

  test "translations have no keys English lacks" do
    AiVisibleContent::TRANSLATED_LOCALES.each do |locale|
      extra_keys = keys_for(locale).reject { |key| key.start_with?("seo.") || I18n.exists?(key, :en) }

      assert_empty extra_keys, "#{locale} has keys English lacks"
    end
  end

  test "every public page has a translated title and description" do
    AiVisibleContent::TRANSLATED_LOCALES.each do |locale|
      AiVisibleContent::PUBLIC_PAGES.each_value do |page|
        %w[ title description ].each do |attribute|
          assert I18n.exists?("seo.pages.#{page[:slug]}.#{attribute}", locale), "Missing seo.pages.#{page[:slug]}.#{attribute} for #{locale}"
        end
      end
    end
  end

  test "public page locales match the configured languages" do
    assert_equal I18n.available_locales.map(&:to_s) - [ I18n.default_locale.to_s ], AiVisibleContent::TRANSLATED_LOCALES
  end

  private
    def keys_for(locale)
      @i18n.data[locale.to_s].key_names(root: false).map(&:to_s)
    end
end
