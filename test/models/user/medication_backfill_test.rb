require "test_helper"

class User::MedicationBackfillTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.medication_doses.delete_all
    @user.medications.destroy_all
    @user.headache_logs.destroy_all
  end

  test "creates one medication per distinct name and a dose per mention" do
    first = legacy_log("oxygen 15 min, sumatriptan 6mg", days_ago: 3)
    second = legacy_log("Oxygen + Verapamil", days_ago: 2)
    legacy_log("O2", days_ago: 1)

    assert_equal 3, @user.backfill_medications

    assert_equal %w[ Oxygen Sumatriptan Verapamil ], @user.medications.alphabetically.pluck(:name)
    assert_equal %w[ oxygen abortive preventive ], @user.medications.alphabetically.pluck(:kind)
    assert_equal 5, @user.medication_doses.count

    oxygen, sumatriptan = first.medication_doses.to_a
    assert_equal [ first.start_time, nil, 15 ], [ oxygen.taken_at, oxygen.amount, oxygen.duration_minutes ]
    assert_equal [ 6, "mg" ], [ sumatriptan.amount, sumatriptan.unit ]
    assert_equal %w[ Oxygen Verapamil ], second.medication_doses.map { |dose| dose.medication.name }
  end

  test "leaves the text untouched and doesn't touch the logs" do
    log = legacy_log("Sumatriptan + Oxygen", days_ago: 1)

    assert_no_changes -> { log.reload.updated_at } do
      @user.backfill_medications
    end

    assert_equal "sumatriptan + oxygen", log.reload.medication
  end

  test "is idempotent" do
    legacy_log("oxygen, sumatriptan", days_ago: 1)

    assert_equal 1, @user.backfill_medications
    assert_no_difference -> { MedicationDose.count } do
      assert_equal 0, @user.backfill_medications
    end
  end

  test "skips logs without medication and 'none'" do
    legacy_log(nil, days_ago: 2)
    legacy_log("none", days_ago: 1)

    @user.backfill_medications

    assert_empty @user.medications
  end

  test "keeps users apart" do
    legacy_log("oxygen", days_ago: 1)
    users(:two).headache_logs.create!(start_time: 1.day.ago, intensity: 5, medication: "oxygen")

    @user.backfill_medications

    assert_equal 1, Medication.where(name: "Oxygen").count
    assert_empty users(:two).medications.where(name: "Oxygen")
  end

  test "verification lists logs whose doses don't match their text" do
    matching = legacy_log("oxygen, sumatriptan", days_ago: 2)
    mismatching = legacy_log("verapamil", days_ago: 1)
    @user.backfill_medications
    mismatching.medication_doses.delete_all

    assert_equal [ mismatching ], @user.logs_with_unmatched_medication_backfill
    assert_not_includes @user.logs_with_unmatched_medication_backfill, matching
  end

  private
    def legacy_log(medication, days_ago:)
      @user.headache_logs.create!(start_time: days_ago.days.ago, end_time: days_ago.days.ago + 1.hour, intensity: 7, medication: medication)
    end
end
