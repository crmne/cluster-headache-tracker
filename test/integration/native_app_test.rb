require "test_helper"

class NativeAppTest < ActionDispatch::IntegrationTest
  ALL_COMPONENTS = %w[ alert button form haptic menu review-prompt share theme toast widget-status ]

  setup do
    @user = users(:two)
    @headache_log = headache_logs(:two)
    @user.update!(welcome_seen_at: Time.current, last_seen_changelog: ChangelogEntry.current.key)
    sign_in @user
  end

  test "flash messages become native toasts with haptic feedback" do
    patch headache_log_url(@headache_log), params: { headache_log: { intensity: 4 } }, headers: native_headers
    follow_redirect! headers: native_headers

    assert_select "#flash-messages[hidden]" do
      assert_select "[data-controller='bridge--toast'][data-bridge-message='Headache log was successfully updated.']"
      assert_select "[data-controller='bridge--haptic'][data-bridge-feedback='success']"
    end
    assert_select ".alert-success", count: 0
  end

  test "flash messages stay in the page when the app can't show toasts" do
    patch headache_log_url(@headache_log), params: { headache_log: { intensity: 4 } }, headers: native_headers(components: %w[ button ])
    follow_redirect! headers: native_headers(components: %w[ button ])

    assert_select ".alert-success", text: /successfully updated/
    assert_select "[data-controller='bridge--toast']", count: 0
    assert_select "[data-controller='bridge--haptic']", count: 0
  end

  test "web flash messages are unchanged" do
    patch headache_log_url(@headache_log), params: { headache_log: { intensity: 4 } }
    follow_redirect!

    assert_select ".alert-success", text: /successfully updated/
    assert_select "[data-controller~='bridge--toast']", count: 0
  end

  test "the body wires native confirms and theme in the apps only" do
    get headache_logs_url, headers: native_headers
    assert_select "body[data-controller='bridge--theme bridge--alert'][data-bridge--alert-confirm-value='OK'][data-bridge--alert-dismiss-value='Cancel']"

    get headache_logs_url
    assert_select "body[data-controller]", count: 0
  end

  test "the dashboard hands the widget status to the app" do
    get headache_logs_url, headers: native_headers

    assert_select "[data-controller='bridge--widget-status']" do |elements|
      status = JSON.parse(elements.first["data-bridge--widget-status-payload-value"])
      assert_equal %w[ ongoing startedAt lastAttackAt attackFreeDays attacksToday locale ], status.keys
      assert_equal false, status["ongoing"]
    end
  end

  test "the web dashboard has no widget status" do
    get headache_logs_url

    assert_select "[data-controller='bridge--widget-status']", count: 0
  end

  test "log forms put their submit button in the native navigation bar" do
    get new_headache_log_url, headers: native_headers

    assert_select "form#headache_log[data-controller='bridge--form']" do
      assert_select "[type=submit][data-bridge--form-target='submit'][data-bridge-title='Create']"
    end
    assert_select "[data-controller='bridge--button']", count: 0
    assert_select "a", text: "Back", count: 0
  end

  test "log forms fall back to a native button when the app has no form component" do
    get edit_headache_log_url(@headache_log), headers: native_headers(components: %w[ button ])

    assert_select "[data-controller='bridge--button'][data-bridge-title='Update']"
  end

  test "log details move their actions into a native menu" do
    get headache_log_url(@headache_log), headers: native_headers

    assert_select "[data-controller='bridge--menu'][hidden]" do
      assert_select "a[data-bridge--menu-target='item'][href='#{edit_headache_log_path(@headache_log)}']", text: "Edit"
      assert_select "button[data-bridge--menu-target='item'][data-bridge-destructive='true'][data-turbo-confirm]", text: "Delete"
    end
    assert_select "a", text: "Back", count: 0
  end

  test "web log details keep the back link and inline actions" do
    get headache_log_url(@headache_log)

    assert_select "a", text: "Back"
    assert_select "[data-controller~='bridge--menu']", count: 0
    assert_select "a[href='#{edit_headache_log_path(@headache_log)}']", text: /Edit/
  end

  test "asks for a review on a calm visit once the app has proven useful" do
    @user.update_column :headache_logs_count, User::ReviewPrompting::REVIEW_PROMPT_MINIMUM_LOGS

    get headache_logs_url, headers: native_headers
    assert_select "[data-controller='bridge--review-prompt'][data-bridge--review-prompt-url-value='#{settings_review_prompt_path}']"

    get headache_logs_url
    assert_select "[data-controller='bridge--review-prompt']", count: 0
  end

  test "never asks for a review during an attack" do
    @user.update_column :headache_logs_count, User::ReviewPrompting::REVIEW_PROMPT_MINIMUM_LOGS
    @headache_log.update!(end_time: nil)

    get headache_logs_url, headers: native_headers

    assert_select "[data-controller='bridge--review-prompt']", count: 0
  end

  test "recording a review prompt postpones the next one" do
    assert_changes -> { @user.reload.review_prompted_at }, from: nil do
      post settings_review_prompt_url, headers: native_headers
    end
    assert_response :no_content
  end

  test "signed-out apps get a 401 so they can present their sign-in flow" do
    sign_out @user

    [ "Hotwire Native iOS; bridge-components: []", "Turbo Native Android" ].each do |user_agent|
      get headache_logs_url, headers: { "User-Agent" => user_agent }
      assert_response :unauthorized, user_agent
    end

    get headache_logs_url
    assert_redirected_to new_user_session_url
  end

  test "our recede route wins over turbo-rails' so the apps can intercept it after sign-in" do
    assert_recognizes({ controller: "recede_historical_locations", action: "show" }, "/recede_historical_location")

    sign_out @user
    post user_session_url, params: { user: { username: @user.username, password: "password123" } }, headers: native_headers
    assert_redirected_to "/recede_historical_location"

    follow_redirect! headers: native_headers
    assert_response :success
    assert_match %(window.location.href = "#{headache_logs_path}"), response.body
    assert_no_match "Going back", response.body
  end

  test "browsers visiting the recede route land on the logs" do
    get "/recede_historical_location"

    assert_redirected_to headache_logs_path
  end

  test "natively handled buttons carry a language-independent action" do
    @user.update!(locale: "de")

    get settings_url, headers: native_headers
    assert_select "[data-controller='bridge--button'][data-bridge-native-action='sign-out']"

    get headache_log_print_url, headers: native_headers
    assert_select "[data-controller='bridge--button'][data-bridge-native-action='print']"
  end

  private
    def native_headers(components: ALL_COMPONENTS)
      { "User-Agent" => "ClusterHeadacheTracker; platform=ios; version=1.2.0; build=12; Hotwire Native iOS; Turbo Native iOS; bridge-components: [#{components.join(" ")}]" }
    end
end
