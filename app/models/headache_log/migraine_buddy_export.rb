require "csv"

# Reads the CSV export of the Migraine Buddy app: a preamble listing ongoing
# events, a blank line, then one row per attack under a header row that
# starts with "#","Started","Lasted".
class HeadacheLog::MigraineBuddyExport
  HEADER_START = [ "#", "Started", "Lasted" ].freeze
  STARTED_FORMAT = "%m/%d/%y %H:%M"
  DURATION_PATTERN = /\A\s*(?:(\d+)\s*d)?\s*(?:(\d+)\s*h)?\s*(?:(\d+)\s*m)?\s*\z/i

  MEDICATION_COLUMNS = [ "Helpful Medication", "Somewhat Helpful Medication", "Unhelpful Medication", "Unsure Medication" ].freeze
  NO_MEDICATION = "no medication"

  # Mapped onto dedicated fields, or (the location geohash) deliberately left out.
  UNNOTED_COLUMNS = [ "#", "Started", "Lasted", "Start UTC Offset (min)", "End UTC Offset (min)", "Geohash", "Pain Level", "Potential Triggers", "Notes" ].freeze

  class << self
    def parse(contents)
      rows = CSV.parse(contents)

      if header_index = rows.index { |row| header?(row) }
        new(headers: rows[header_index].map { |header| header.to_s.strip }, rows: rows.drop(header_index + 1))
      end
    end

    private
      def header?(row)
        row.first(HEADER_START.size).map { |cell| cell.to_s.strip } == HEADER_START
      end
  end

  def initialize(headers:, rows:)
    @headers = headers
    @rows = rows.reject { |row| row.all?(&:blank?) }
  end

  # One attributes hash per attack, or nil when the row can't be read.
  def log_attributes
    @rows.map do |row|
      attributes_from @headers.zip(row.map { |cell| cell.to_s.strip }).to_h
    end
  end

  private
    def attributes_from(attack)
      if start_time = start_time_from(attack)
        {
          start_time: start_time,
          end_time: end_time_from(attack, start_time),
          intensity: intensity_from(attack),
          medication: medications_from(attack).join(", "),
          triggers: attack["Potential Triggers"],
          notes: notes_from(attack)
        }
      end
    end

    # "Started" is the local wall-clock time; the offset is minutes east of UTC.
    def start_time_from(attack)
      local_time = DateTime.strptime(attack["Started"].to_s, STARTED_FORMAT)
      (local_time.to_time - utc_offset_from(attack["Start UTC Offset (min)"]).minutes).in_time_zone
    rescue Date::Error
      nil
    end

    def utc_offset_from(minutes)
      Integer(minutes.presence || 0, exception: false) || 0
    end

    # "Lasted" is the elapsed duration, e.g. "01h 00m" or "1d 02h 15m".
    def end_time_from(attack, start_time)
      if (match = DURATION_PATTERN.match(attack["Lasted"].to_s)) && match.captures.any?
        days, hours, minutes = match.captures.map(&:to_i)
        start_time + days.days + hours.hours + minutes.minutes
      end
    end

    # Migraine Buddy rates pain from 0 to 10; the lowest intensity here is 1.
    def intensity_from(attack)
      if pain_level = Integer(attack["Pain Level"].presence || "", exception: false)
        pain_level.zero? ? 1 : pain_level
      end
    end

    def medications_from(attack)
      MEDICATION_COLUMNS.flat_map { |column| list_from(attack[column]) }.uniq
    end

    def list_from(value)
      value.to_s.split(",").map(&:strip).reject { |item| item.blank? || item.casecmp?(NO_MEDICATION) }
    end

    def notes_from(attack)
      details = (@headers - UNNOTED_COLUMNS).filter_map do |column|
        if (values = list_from(attack[column])).any?
          "#{column}: #{values.join(", ")}"
        end
      end

      [ attack["Notes"].presence, details.join("\n").presence ].compact.join("\n\n")
    end
end
