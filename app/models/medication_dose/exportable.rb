require "csv"

# Every dose, standalone or taken during an attack, as its own CSV. The
# headache log CSV keeps naming each attack's medication as text; this file
# adds what text can't carry (exact times, ratings, time to relief) and the
# doses taken outside attacks. Import the headache logs first: dose rows
# then find their attack by its start time and enrich the doses the log
# import created instead of duplicating them.
module MedicationDose::Exportable
  extend ActiveSupport::Concern

  CSV_HEADERS = %w[ taken_at medication kind amount unit duration_minutes effectiveness minutes_to_relief attack_start_time ].freeze
  CSV_TIME_FORMAT = "%Y-%m-%d %H:%M:%S"

  class_methods do
    def csv_file?(file)
      CSV.open(file.path, &:readline).to_a.include?("taken_at")
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << CSV_HEADERS

        recent_first.includes(:medication, :headache_log).each do |dose|
          csv << dose.to_csv_row
        end
      end
    end

    def import_csv(file:, user:)
      imported_doses = 0

      CSV.foreach(file.path, headers: true, header_converters: :symbol) do |row|
        if row[:medication].present? && import_csv_row(row, user: user)
          imported_doses += 1
        end
      end

      imported_doses
    end

    private
      def import_csv_row(row, user:)
        medication = user.medications.resolve(row[:medication], kind: row[:kind].presence_in(Medication::KINDS))
        taken_at = parse_csv_time(row[:taken_at])
        headache_log = (start_time = parse_csv_time(row[:attack_start_time])) && user.headache_logs.find_by(start_time: start_time)

        dose = matching_dose_for(user: user, medication: medication, taken_at: taken_at, headache_log: headache_log)
        dose.update \
          headache_log: headache_log || dose.headache_log,
          taken_at: taken_at,
          amount: row[:amount].presence,
          unit: row[:unit].presence,
          duration_minutes: row[:duration_minutes].presence,
          effectiveness: row[:effectiveness].presence_in(MedicationDose::EFFECTIVENESS),
          minutes_to_relief: row[:minutes_to_relief].presence
      end

      # The headache log import records each attack's doses at the attack's
      # start time; a dose row for that attack replaces one of those.
      def matching_dose_for(user:, medication:, taken_at:, headache_log:)
        user.medication_doses.find_by(medication: medication, taken_at: taken_at) ||
          headache_log&.medication_doses&.find_by(medication: medication, taken_at: headache_log.start_time) ||
          user.medication_doses.new(medication: medication)
      end

      def parse_csv_time(value)
        Time.zone.parse(value) if value.present?
      end
  end

  def to_csv_row
    [
      taken_at.strftime(CSV_TIME_FORMAT),
      medication.name,
      medication.kind,
      amount && MedicationDose.format_amount(amount),
      unit,
      duration_minutes,
      effectiveness,
      minutes_to_relief,
      headache_log&.start_time&.strftime(CSV_TIME_FORMAT)
    ]
  end
end
