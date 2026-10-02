require "application_system_test_case"

class OngoingAttackBannerTest < ApplicationSystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ]

  setup do
    @user = users(:one)
    @user.update!(welcome_seen_at: Time.current, last_seen_changelog: ChangelogEntry.current.key)
    @attack = headache_logs(:one)
    @attack.update!(end_time: nil)
    sign_in @user
  end

  test "the banner fits a phone screen in light and dark" do
    %w[ light dark ].each do |scheme|
      page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [ { name: "prefers-color-scheme", value: scheme } ])

      [ headache_logs_path, headache_log_path(@attack), new_headache_log_path ].each do |path|
        visit path

        within("#ongoing_headache_alert") do
          assert_selector "#end_ongoing_headache", text: "End attack now"
          assert_selector "a", text: "Edit"
        end
        assert_fully_inside_viewport "#end_ongoing_headache", "#{path} (#{scheme})"
        assert_fully_inside_viewport "#ongoing_headache_alert a", "#{path} (#{scheme})"
      end
    end
  end

  private
    def assert_fully_inside_viewport(selector, context)
      rect = evaluate_script(<<~JS, selector)
        (() => {
          const element = document.querySelector(arguments[0])
          const { left, right, height } = element.getBoundingClientRect()
          return { left, right, height, width: document.documentElement.clientWidth, clipped: element.scrollWidth > element.clientWidth }
        })()
      JS

      assert_operator rect["left"], :>=, 0, "#{selector} starts off screen on #{context}"
      assert_operator rect["right"], :<=, rect["width"], "#{selector} ends off screen on #{context}"
      assert_operator rect["height"], :>=, 48, "#{selector} is too small to tap on #{context}"
      assert_not rect["clipped"], "#{selector} clips its label on #{context}"
    end
end
