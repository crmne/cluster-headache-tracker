require "application_system_test_case"

class QuickLogTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @user.update!(welcome_seen_at: Time.current, last_seen_changelog: ChangelogEntry.current.key)
    sign_in @user
  end

  test "logging an attack with one tap and ending it" do
    visit new_headache_log_url(quick: 1)

    assert_selector "h1", text: "Start attack now"
    find("#start_attack button[value='8']").click

    assert_current_path current_attack_path
    assert_selector "h1", text: "Attack in progress"
    assert_text "Pain 8/10"

    attack = @user.headache_logs.ongoing.sole
    assert_equal 8, attack.intensity

    click_on "End attack now"

    assert_current_path current_attack_path
    assert_text "Attack ended."
    assert_selector "h1", text: "Start attack now"
    assert_not_nil attack.reload.end_time
  end

  test "ending the ongoing attack from the dashboard" do
    attack = headache_logs(:one)
    attack.update!(end_time: nil)

    visit headache_logs_url
    within("div[role='alert'].alert-warning") do
      click_on "End attack now"
    end

    assert_no_text "Ongoing Headache"
    assert_current_path headache_logs_path
    assert_not_nil attack.reload.end_time
  end

  test "keyboard shortcuts open the help, the current attack and a new log" do
    visit headache_logs_url

    press_key "?"
    assert_selector "dialog#keyboard_shortcuts[open]", text: "Keyboard shortcuts"
    within("dialog#keyboard_shortcuts") { click_on "Close" }
    assert_no_selector "dialog#keyboard_shortcuts[open]"

    press_key "e"
    assert_current_path current_attack_path

    press_key "n"
    assert_current_path new_headache_log_path
  end

  test "keyboard shortcuts stay quiet while typing" do
    visit new_headache_log_url

    fill_in "headache_log[notes]", with: "Pacing"
    press_key "e", on: "#headache_log_notes"

    assert_current_path new_headache_log_path
    assert_field "headache_log[notes]", with: "Pacing"
  end

  test "single-key shortcuts can be turned off" do
    visit headache_logs_url

    press_key "?"
    within("dialog#keyboard_shortcuts") do
      uncheck "Single-key shortcuts"
      click_on "Close"
    end
    press_key "e"

    assert_current_path headache_logs_path
  ensure
    execute_script("localStorage.clear()")
  end

  private
    # Chromedriver types through the host keyboard layout, so dispatch the key the user would produce.
    def press_key(key, on: "body")
      execute_script(<<~JS, on, key)
        document.querySelector(arguments[0]).dispatchEvent(new KeyboardEvent("keydown", { key: arguments[1], bubbles: true }))
      JS
    end
end
