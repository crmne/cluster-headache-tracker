# Moves the free-text medication of logs written before medications became
# records into Medication and MedicationDose records. Run per user by
# `bin/rails medications:backfill`; safe to run repeatedly, since logs that
# already have doses are skipped. The text column is left untouched so the
# result can be checked with `bin/rails medications:verify`.
module User::MedicationBackfill
  extend ActiveSupport::Concern

  def backfill_medications
    logs_awaiting_medication_backfill.find_each.sum do |headache_log|
      transaction do
        Medication::Legacy.parse(headache_log.medication).each do |entry|
          medication_doses.create! \
            medication: medications.resolve(entry.name),
            headache_log: headache_log,
            taken_at: headache_log.start_time,
            amount: entry.amount,
            unit: entry.unit,
            duration_minutes: entry.duration_minutes,
            skip_headache_log_refresh: true
        end
      end

      1
    end
  end

  # Logs whose doses don't name the medications their text mentions.
  def logs_with_unmatched_medication_backfill
    headache_logs.where.not(medication: [ nil, "" ]).includes(medication_doses: :medication).select do |headache_log|
      mentioned = Medication::Legacy.parse(headache_log.medication).map { |entry| entry.name.downcase }
      recorded = headache_log.medication_doses.map { |dose| dose.medication.name.downcase }

      mentioned.tally != recorded.tally
    end
  end

  private
    def logs_awaiting_medication_backfill
      headache_logs.where.not(medication: [ nil, "" ]).where.missing(:medication_doses)
    end
end
