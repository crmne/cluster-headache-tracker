require "application_system_test_case"

class ChartsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "viewing charts" do
    visit charts_url
    assert_selector "canvas#intensityChart"
    assert_selector "canvas#triggerChart"
    assert_selector "canvas#medicationChart"
    assert_selector "canvas#hourlyChart"
    assert_selector "canvas#attacksPerDayChart"
    assert_selector "canvas#pressureChart"
    assert_text "Log the pressure for attacks less than 24 hours apart"
  end

  test "viewing pressure change between attacks" do
    headache_logs(:three).update!(start_time: headache_logs(:one).start_time - 6.hours)

    visit charts_url
    assert_selector "canvas#pressureChangeChart"
  end

  test "viewing charts in German with a 24-hour clock" do
    @user.update!(locale: "de")

    visit charts_url

    assert_selector "h2", text: "Schmerzintensität im Verlauf"
    assert_selector "canvas#hourlyChart"

    hourly_chart = <<~JS
      window.Stimulus.getControllerForElementAndIdentifier(document.querySelector("[data-controller=charts]"), "charts").charts.hourly
    JS
    assert_equal "20:00 – 21:59", evaluate_script("#{hourly_chart}.data.labels[10]")
    assert_equal "Uhrzeit", evaluate_script("#{hourly_chart}.options.scales.x.title.text")
  end
end
