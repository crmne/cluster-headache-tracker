# Rollout of structured medication tracking (issues #9 and #74):
#
# 1. Deploy. New and edited logs record MedicationDose rows and mirror them
#    into headache_logs.medication, so the text column stays complete.
# 2. bin/rails medications:backfill — turns the text of older logs into
#    Medication and MedicationDose records. Idempotent: logs that already
#    have doses are skipped, so it can be re-run after a partial failure.
# 3. bin/rails medications:verify — lists logs whose doses don't match the
#    medications named in their text. Exits non-zero when any are found.
# 4. Once verified in production, a follow-up release stops reading and
#    mirroring headache_logs.medication and drops the column.
namespace :medications do
  desc "Create medications and doses from the free-text medication of existing headache logs"
  task backfill: :environment do
    failures = []

    User.where(id: HeadacheLog.where.not(medication: [ nil, "" ]).select(:user_id)).find_each do |user|
      backfilled = user.backfill_medications
      puts "User #{user.id}: backfilled #{backfilled} headache logs" if backfilled.positive?
    rescue ActiveRecord::ActiveRecordError => error
      failures << user.id
      puts "User #{user.id}: failed (#{error.class}: #{error.message})"
    end

    if failures.any?
      abort "Backfill failed for #{failures.size} users: #{failures.join(", ")}"
    else
      puts "Backfill complete: #{Medication.count} medications, #{MedicationDose.count} doses"
    end
  end

  desc "Check that every backfilled headache log has doses for each medication its text names"
  task verify: :environment do
    unmatched = User.where(id: HeadacheLog.where.not(medication: [ nil, "" ]).select(:user_id)).flat_map do |user|
      user.logs_with_unmatched_medication_backfill
    end

    # IDs and counts only: medication names are health data.
    unmatched.each do |headache_log|
      puts "HeadacheLog #{headache_log.id} (user #{headache_log.user_id}): " \
        "#{Medication::Legacy.parse(headache_log.medication).size} mentioned, #{headache_log.medication_doses.size} recorded"
    end

    if unmatched.any?
      abort "#{unmatched.size} headache logs don't match their medication text"
    else
      puts "All headache logs match their medication text"
    end
  end
end
