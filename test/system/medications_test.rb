require "application_system_test_case"

class MedicationsTest < ApplicationSystemTestCase
  include ActionView::RecordIdentifier

  setup do
    @user = users(:one)
    @user.update!(welcome_seen_at: Time.current, last_seen_changelog: ChangelogEntry.current.key)
    sign_in @user
  end

  test "one tap adds a dose taken now to a new attack" do
    visit new_headache_log_url

    click_on "Oxygen"
    within "[data-medication-picker-target=doses]" do
      assert_selector ".medication-tag", text: "Oxygen"
      assert_field "Flow rate (L/min)", with: "15"
      fill_in "Duration (minutes)", with: "20"
    end

    click_button "Create Headache log"

    assert_text "Headache log was successfully created."
    log = @user.headache_logs.order(:created_at).last
    dose = log.medication_doses.sole
    assert_equal [ medications(:oxygen), 15, 20 ], [ dose.medication, dose.amount, dose.duration_minutes ]
    assert_in_delta Time.zone.parse(Time.now.strftime("%Y-%m-%d %H:%M")), dose.taken_at, 2.minutes
    assert_selector "##{dom_id(log)} .medication-tag", text: "Oxygen · 15 L/min · 20 min"
  end

  test "creates a new medication from the picker and removes a dose before saving" do
    visit new_headache_log_url

    click_on "Sumatriptan"
    click_button "New"
    fill_in "new_medication_name", with: "Lidocaine"
    click_button "Add"

    within "[data-medication-picker-target=doses]" do
      assert_selector ".medication-tag", text: "Lidocaine"
      click_button "Remove Sumatriptan"
      assert_no_selector ".medication-tag", text: "Sumatriptan"
    end

    click_button "Create Headache log"

    assert_text "Headache log was successfully created."
    assert @user.medications.named("Lidocaine").abortive?
    assert_equal [ "Lidocaine" ], @user.headache_logs.order(:created_at).last.medication_doses.map { |dose| dose.medication.name }
  end

  test "removing a saved dose while editing an attack" do
    log = headache_logs(:three)
    visit edit_headache_log_url(log)

    click_button "Remove Oxygen"
    click_button "Update Headache log"

    assert_text "Headache log was successfully updated."
    assert_equal [ "Sumatriptan" ], log.reload.medication_doses.map { |dose| dose.medication.name }
  end

  test "rating a dose after the attack ended" do
    log = headache_logs(:one)
    log.update!(start_time: 2.hours.ago, end_time: 30.minutes.ago)
    dose = medication_doses(:zolmitriptan_for_one)

    visit headache_logs_url

    within "##{dom_id(log, :dose_review)}" do
      assert_text "How did Zolmitriptan work?"
      click_button "Helped"
      assert_text "How long until Zolmitriptan brought relief?"
      click_button "15 min"
      assert_text "Thanks, saved."
    end

    assert_equal [ "helped", 15 ], [ dose.reload.effectiveness, dose.minutes_to_relief ]
    assert_selector "##{dom_id(log)} [aria-label=Helped]"
  end

  test "postponing the rating hides the prompt on this device" do
    log = headache_logs(:one)
    log.update!(start_time: 2.hours.ago, end_time: 30.minutes.ago)

    visit headache_logs_url
    within("##{dom_id(log, :dose_review)}") { click_button "Later" }
    assert_no_selector "##{dom_id(log, :dose_review)}"

    visit headache_logs_url
    assert_no_selector "##{dom_id(log, :dose_review)}", visible: true
  end

  test "logging a preventive from the dashboard" do
    visit headache_logs_url

    within "#due_medications" do
      assert_text "0 of 2 today"
      click_button "Took it"
    end

    assert_text "Lithium dose logged."
    within("#due_medications") { assert_text "1 of 2 today" }
  end

  test "managing medications and browsing the timeline" do
    visit medications_url
    within(".navbar") { click_on "New" }

    fill_in "Name", with: "Verapamil"
    choose "Preventive"
    fill_in "Usual dose", with: "240"
    fill_in "Unit", with: "mg"
    select "Three times a day", from: "How often"
    click_button "Save"

    assert_text "Verapamil was added."
    click_button "Log a dose of Verapamil taken now"
    assert_text "Verapamil dose logged."

    visit timeline_url
    assert_selector "#timeline .medication-tag", text: "Verapamil · 240 mg"
    assert_selector "#timeline .medication-tag", text: "Oxygen · 15 L/min · 15 min"
  end
end
