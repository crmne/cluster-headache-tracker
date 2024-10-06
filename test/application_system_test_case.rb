require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  teardown do
    assert_no_js_errors verify: false
    # assert_no_console_messages
  end

  def assert_no_js_errors(verify: true)
    errors = JSON.parse(evaluate_script("JSON.stringify(window.errorTracker?.errors || false)"))

    assert errors.empty?, errors.map { |error| error["stack"] }.join("\n\n") if errors
  end

  def assert_no_console_messages(level = nil) # "SEVERE"
    logs = page.driver.browser.logs.get(:browser)
    logs = logs.select { |log| log.level == level } if level
    assert logs.empty?, "Unexpected console messages:\n" + logs.map(&:message).join("\n\n")
  end
end
