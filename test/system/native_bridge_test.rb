require "application_system_test_case"

# Drives the web side of the bridge components with a fake native adapter standing in
# for the iOS/Android apps, recording every message the page sends.
class NativeBridgeTest < ApplicationSystemTestCase
  COMPONENTS = %w[ alert button form haptic menu review-prompt share theme toast widget-status ]
  USER_AGENT = "ClusterHeadacheTracker; platform=ios; version=1.2.0; build=12; Hotwire Native iOS; Turbo Native iOS; bridge-components: [#{COMPONENTS.join(" ")}]"

  driven_by :selenium, using: :headless_chrome, screen_size: [ 390, 844 ], options: { name: :native_headless_chrome } do |options|
    options.add_argument "--user-agent=#{USER_AGENT}"
  end

  setup do
    @user = users(:two)
    @headache_log = headache_logs(:two)
    @user.update!(welcome_seen_at: Time.current, last_seen_changelog: ChangelogEntry.current.key)
    sign_in @user
  end

  test "the dashboard announces the widget status, theme and navigation button" do
    visit headache_logs_url
    connect_native_adapter

    status = message_for("widget-status")
    assert_equal "connect", status["event"]
    assert_equal false, status["data"]["ongoing"]
    assert_equal "en", status["data"]["locale"]

    assert_nil message_for("theme")["data"]["theme"]
    button = message_for("button")
    assert_equal "right", button["event"]
    assert_equal({ "title" => "New", "iosImage" => "plus", "androidImage" => "add" }, button["data"].slice("title", "iosImage", "androidImage"))
  end

  test "saving a log from the native navigation bar shows a toast and vibrates" do
    visit edit_headache_log_url(@headache_log)
    connect_native_adapter

    form = message_for("form")
    assert_equal({ "title" => "Update" }, form["data"].slice("title"))

    reply_to form
    assert_current_path headache_logs_path
    wait_for_message "toast"

    assert_equal "Headache log was successfully updated.", message_for("toast")["data"]["message"]
    assert_equal "success", message_for("haptic")["data"]["feedback"]
  end

  test "deleting a log from the native menu asks for confirmation natively" do
    visit headache_log_url(@headache_log)
    connect_native_adapter

    menu = message_for("menu")
    assert_equal [ [ "Edit", false ], [ "Delete", true ] ], menu["data"]["items"].map { |item| [ item["title"], item["destructive"] ] }

    reply_to menu, data: { index: 1 }
    wait_for_message "alert"

    alert = message_for("alert")
    assert_equal "show", alert["event"]
    assert_equal({ "title" => "Are you sure you want to delete this headache log?", "destructive" => true, "confirm" => "Delete", "dismiss" => "Cancel" },
      alert["data"].slice("title", "destructive", "confirm", "dismiss"))
    assert HeadacheLog.exists?(@headache_log.id), "Deleted before the native alert was confirmed"

    reply_to alert
    wait_for_message "toast"

    assert_equal "Headache log was successfully destroyed.", message_for("toast")["data"]["message"]
    assert_not HeadacheLog.exists?(@headache_log.id)
  end

  test "dismissing the native alert keeps the log" do
    visit headache_log_url(@headache_log)
    connect_native_adapter

    reply_to message_for("menu"), data: { index: 1 }
    wait_for_message "alert"

    assert HeadacheLog.exists?(@headache_log.id)
    assert_current_path headache_log_path(@headache_log)
  end

  private
    def connect_native_adapter
      execute_script <<~JS
        window.bridgeMessages = []
        window.HotwireNative.web.setAdapter({
          platform: "ios",
          supportedComponents: #{COMPONENTS.to_json},
          supportsComponent(component) { return this.supportedComponents.includes(component) },
          receive(message) { window.bridgeMessages.push(JSON.parse(JSON.stringify(message))) }
        })
      JS
    end

    def reply_to(message, data: message["data"])
      execute_script "window.HotwireNative.web.receive(arguments[0])", message.merge("data" => data)
    end

    def wait_for_message(component)
      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep 0.05 until message_for(component)
      end
    end

    def message_for(component)
      evaluate_script("window.bridgeMessages").reverse.find { |message| message["component"] == component }
    end
end
