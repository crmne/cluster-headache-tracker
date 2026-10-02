require "test_helper"
require "rake"

class MedicationsRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?

    MedicationDose.delete_all
    Medication.delete_all
  end

  teardown do
    Rake::Task["medications:backfill"].reenable
    Rake::Task["medications:verify"].reenable
  end

  test "backfill creates medications and doses for every user, then verify passes" do
    assert_output(/Backfill complete: 4 medications, 4 doses/) do
      Rake::Task["medications:backfill"].invoke
    end

    assert_equal %w[ Oxygen Sumatriptan Zolmitriptan ], users(:one).medications.alphabetically.pluck(:name)
    assert_equal [ "Sumatriptan" ], users(:two).medications.pluck(:name)

    assert_output(/All headache logs match/) do
      Rake::Task["medications:verify"].invoke
    end
  end

  test "verify fails when a log's doses don't match its text" do
    capture_io { Rake::Task["medications:backfill"].invoke }
    headache_logs(:three).medication_doses.first.destroy!
    HeadacheLog.where(id: headache_logs(:three)).update_all(medication: "Sumatriptan + Oxygen")

    output, = capture_io do
      assert_raises(SystemExit) { Rake::Task["medications:verify"].invoke }
    end

    assert_match "HeadacheLog #{headache_logs(:three).id}", output
    assert_no_match(/sumatriptan/i, output, "medication names are health data and stay out of the output")
  end
end
