require "test_helper"

class MedicationTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "names are unique per user regardless of case" do
    duplicate = @user.medications.new(name: "  oxygen ", kind: "oxygen")

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:name, :taken)
    assert users(:two).medications.new(name: "Oxygen").valid?
  end

  test "squishes names and rejects unknown kinds and frequencies" do
    medication = @user.medications.new(name: "  Verapamil   SR ")

    assert_equal "Verapamil SR", medication.name
    assert_not @user.medications.new(name: "Verapamil", kind: "magic").valid?
    assert_not @user.medications.new(name: "Verapamil", frequency: "hourly").valid?
  end

  test "assigns a tag color and an oxygen unit on create" do
    oxygen = users(:two).medications.create!(name: "O2 tank", kind: "oxygen")
    verapamil = @user.medications.create!(name: "Verapamil", kind: "preventive")

    assert_equal Medication::OXYGEN_COLOR, oxygen.color
    assert_equal "L/min", oxygen.unit
    assert_includes Medication::COLORS, verapamil.color
    assert_equal verapamil.color, @user.medications.new(name: "verapamil").display_color
  end

  test "rejects colors that aren't hex codes" do
    assert_not @user.medications.new(name: "Melatonin", color: "red").valid?
  end

  test "resolve finds medications by name ignoring case or creates them with an inferred kind" do
    assert_equal medications(:oxygen), @user.medications.resolve("OXYGEN")

    assert_difference -> { @user.medications.count } do
      verapamil = @user.medications.resolve("verapamil")

      assert verapamil.preventive?
    end

    assert @user.medications.resolve("Ibuprofen").other?
    assert @user.medications.resolve("Rizatriptan").abortive?
    assert @user.medications.resolve("Melatonin", kind: "other").other?
  end

  test "orders by most recent dose, unused medications last" do
    medications = @user.medications.active.by_recent_use.to_a

    assert_equal medications(:zolmitriptan), medications.first
    assert_equal medications(:emgality), medications.last
  end

  test "archiving hides a medication from the active list but keeps its doses" do
    medication = medications(:sumatriptan)
    medication.update!(archived: "1")

    assert medication.archived?
    assert_not_includes @user.medications.active, medication
    assert_includes @user.medications.archived, medication
    assert medication.doses.any?

    medication.update!(archived: "0")
    assert_not medication.archived?
  end

  test "merging moves every dose and removes the duplicate" do
    typo = @user.medications.create!(name: "Sumatriptin", kind: "abortive")
    dose = typo.doses.create!(user: @user, taken_at: 1.hour.ago, skip_headache_log_refresh: true)

    typo.merge_into(medications(:sumatriptan))

    assert_not Medication.exists?(typo.id)
    assert_equal medications(:sumatriptan), dose.reload.medication
  end

  test "schedules: doses per day, intervals and next due date" do
    lithium = medications(:lithium)
    emgality = medications(:emgality)

    assert lithium.daily?
    assert_equal 2, lithium.doses_per_day
    assert_nil lithium.next_due_at

    assert_equal 1.month, emgality.dosing_interval
    assert_nil emgality.next_due_at

    taken_at = 25.days.ago.change(usec: 0)
    emgality.doses.create!(user: @user, taken_at: taken_at)
    assert_equal taken_at + 1.month, emgality.next_due_at
  end

  test "a daily preventive is due until today's doses are taken" do
    lithium = medications(:lithium)
    assert lithium.due?

    2.times { lithium.doses.create!(user: @user, taken_at: Time.current) }
    assert_not lithium.due?
  end

  test "a long-interval preventive is due a few days before its next dose" do
    emgality = medications(:emgality)
    assert_not emgality.due?, "never taken, nothing to count from"

    emgality.doses.create!(user: @user, taken_at: 29.days.ago)
    assert emgality.due?

    emgality.doses.create!(user: @user, taken_at: 20.days.ago)
    assert_not emgality.due?
  end

  test "coverage counts daily doses up to the schedule and interval doses across their interval" do
    lithium = medications(:lithium)
    emgality = medications(:emgality)
    today = Date.current

    assert_equal 0.5, lithium.coverage_on(today, [ today ])
    assert_equal 1.0, lithium.coverage_on(today, [ today, today, today ])
    assert_equal 0.0, lithium.coverage_on(today, [ today - 1 ])

    assert_equal 1.0, emgality.coverage_on(today, [ today - 20 ])
    assert_equal 0.0, emgality.coverage_on(today, [ today - 40 ])
    assert_nil medications(:oxygen).coverage_on(today, [ today ])
  end
end
