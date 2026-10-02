require "test_helper"

class MedicationDoseTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "labels read like the old free text" do
    assert_equal "Oxygen 15 L/min 15 min", medication_doses(:oxygen_for_three).label
    assert_equal "Zolmitriptan", medication_doses(:zolmitriptan_for_one).label
    assert_equal "6 mg", medication_doses(:sumatriptan_for_three).amount_label
  end

  test "takes the medication's unit when a dose is given without one" do
    dose = @user.medication_doses.create!(medication: medications(:sumatriptan), amount: 6, taken_at: 3.days.ago)

    assert_equal "mg", dose.unit
  end

  test "creates a medication typed by name, reusing an existing one ignoring case" do
    assert_no_difference -> { Medication.count } do
      dose = @user.medication_doses.create!(medication_name: "sumatriptan", taken_at: 3.days.ago)
      assert_equal medications(:sumatriptan), dose.medication
    end

    assert_difference -> { @user.medications.count } do
      dose = @user.medication_doses.create!(medication_name: "Verapamil", medication_kind: "preventive", taken_at: 3.days.ago)
      assert dose.medication.preventive?
    end
  end

  test "can't use another user's medication or attack" do
    dose = @user.medication_doses.new(medication: medications(:sumatriptan_two), taken_at: Time.current)
    assert_not dose.valid?
    assert dose.errors.of_kind?(:medication, :invalid)

    dose = @user.medication_doses.new(medication: medications(:oxygen), headache_log: headache_logs(:two), taken_at: Time.current)
    assert_not dose.valid?
    assert dose.errors.of_kind?(:headache_log, :invalid)
  end

  test "validates amounts, durations and time to relief" do
    dose = @user.medication_doses.new(medication: medications(:oxygen), amount: -1, duration_minutes: 0, minutes_to_relief: -5)

    assert_not dose.valid?
    assert dose.errors.of_kind?(:amount, :greater_than_or_equal_to)
    assert dose.errors.of_kind?(:duration_minutes, :greater_than)
    assert dose.errors.of_kind?(:minutes_to_relief, :greater_than_or_equal_to)
    assert_not @user.medication_doses.new(medication: medications(:oxygen), effectiveness: "cured").valid?
  end

  test "an abortive taken while an attack is going on is attached to it" do
    attack = @user.headache_logs.create!(start_time: 20.minutes.ago, intensity: 8)

    dose = @user.medication_doses.create!(medication: medications(:oxygen), taken_at: 5.minutes.ago)

    assert_equal attack, dose.headache_log
    assert_equal "oxygen", attack.reload.medication
  end

  test "a preventive taken during an attack stays on its own" do
    @user.headache_logs.create!(start_time: 20.minutes.ago, intensity: 8)

    dose = @user.medication_doses.create!(medication: medications(:lithium), taken_at: 5.minutes.ago)

    assert_nil dose.headache_log
  end

  test "a dose long after a forgotten ongoing attack began stays on its own" do
    @user.headache_logs.create!(start_time: 2.days.ago, intensity: 8)

    assert_nil @user.medication_doses.create!(medication: medications(:oxygen), taken_at: 1.minute.ago).headache_log
  end

  test "changing or removing a dose keeps its attack's text in sync" do
    dose = medication_doses(:oxygen_for_three)
    attack = dose.headache_log

    dose.update!(duration_minutes: 25)
    assert_equal "sumatriptan 6 mg, oxygen 15 l/min 25 min", attack.reload.medication

    dose.destroy!
    assert_equal "sumatriptan 6 mg", attack.reload.medication
  end

  test "rating a dose leaves its attack alone" do
    dose = medication_doses(:zolmitriptan_for_one)

    assert_no_changes -> { dose.headache_log.reload.updated_at } do
      dose.update!(effectiveness: "helped", minutes_to_relief: 10)
    end
  end

  test "minutes until the attack ended" do
    dose = medication_doses(:oxygen_for_three)

    assert_equal 100, dose.minutes_until_attack_ended
    assert_nil medication_doses(:lithium_yesterday).minutes_until_attack_ended
  end

  test "exports every dose to CSV" do
    csv = CSV.parse(@user.medication_doses.to_csv, headers: true)

    assert_equal MedicationDose::CSV_HEADERS, csv.headers
    assert_equal @user.medication_doses.count, csv.size

    oxygen = csv.find { |row| row["medication"] == "Oxygen" }
    assert_equal [ "oxygen", "15", "L/min", "15", "helped", "12" ], oxygen.fields("kind", "amount", "unit", "duration_minutes", "effectiveness", "minutes_to_relief")
    assert_equal headache_logs(:three).start_time.strftime("%Y-%m-%d %H:%M:%S"), oxygen["attack_start_time"]
  end

  test "detects dose CSV files" do
    assert MedicationDose.csv_file?(csv_file(@user.medication_doses.to_csv))
    assert_not MedicationDose.csv_file?(File.open(file_fixture("sample_logs.csv")))
  end

  test "importing logs and then doses restores times, ratings and standalone doses without duplicates" do
    logs_csv = @user.headache_logs.to_csv
    doses_csv = @user.medication_doses.to_csv
    exported = doses_csv.lines.drop(1).sort

    @user.headache_logs.destroy_all
    @user.medication_doses.delete_all

    HeadacheLog.import_csv(file: csv_file(logs_csv), user: @user)
    assert_equal 4, MedicationDose.import_csv(file: csv_file(doses_csv), user: @user)

    assert_equal 4, @user.medication_doses.count
    assert_equal exported, @user.medication_doses.to_csv.lines.drop(1).sort
  end

  private
    def csv_file(content)
      Tempfile.new([ "doses", ".csv" ]).tap do |file|
        file.write(content)
        file.rewind
      end
    end
end
