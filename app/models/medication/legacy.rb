# Reads the free-text medication people typed into headache logs before
# medications were their own records ("oxygen 15 min, sumatriptan 6mg",
# "Sumatriptan + O2") and turns each mention into a structured entry. Used
# by the backfill of existing logs and by CSV import, which keeps reading
# the same text column. MedicationDose#label writes the inverse, so a log
# exported and imported again comes back with the same doses.
module Medication::Legacy
  Entry = Data.define(:name, :amount, :unit, :duration_minutes)

  SEPARATOR = /\s*(?:[,;+&]|\band\b)\s*/i
  DURATION = /(?<minutes>\d+)\s*(?:minutes?|mins?)(?![[:alpha:]])/i
  AMOUNT_WITH_UNIT = %r{(?<amount>\d+(?:\.\d+)?)\s*(?<unit>l/min|lpm|mcg|µg|ug|mg|ml|iu|units?|puffs?|sprays?|tablets?|tabs?|pills?|g|l)(?![[:alpha:]/])}i
  BARE_AMOUNT = /(?:\A|\s)(?<amount>\d+(?:\.\d+)?)\s*\z/

  UNITS = {
    "l/min" => "L/min", "lpm" => "L/min", "l" => "L/min",
    "mcg" => "mcg", "µg" => "mcg", "ug" => "mcg", "mg" => "mg", "g" => "g", "ml" => "ml",
    "iu" => "IU", "unit" => "units", "units" => "units",
    "puff" => "puffs", "puffs" => "puffs", "spray" => "sprays", "sprays" => "sprays",
    "tablet" => "tablets", "tablets" => "tablets", "tab" => "tablets", "tabs" => "tablets",
    "pill" => "tablets", "pills" => "tablets"
  }.freeze

  NOTHING = %r{\A(?:none|no|nothing|nil|n/?a|-+|keine?|nichts|nessuno|niente|nada|ninguno)\z}i
  OXYGEN = /\A(?:oxygen|o2|oxigen|oxygene|sauerstoff|ossigeno|ox[ií]geno)\z/
  PREVENTIVES = /verapamil|lithium|prednis|dexamethason|topiramat|melatonin|galcanezumab|emgality|botox|onabotulinum|gabapentin|valpro|methysergid|candesartan|vitamin d|\bd3\b/
  ABORTIVES = /triptan|imitrex|imigran|zomig|maxalt|lidocain|dihydroergotamin|\bdhe\b|ergotamin|octreotid/

  extend self

  def parse(text)
    text.to_s.split(SEPARATOR).each_with_object([]) do |mention, entries|
      if entry = parse_mention(mention)
        if entry.name.present?
          entries << entry
        elsif previous = entries.pop
          # "oxygen, 15 min": a bare dose belongs to the medication before it
          entries << previous.with(
            amount: previous.amount || entry.amount,
            unit: previous.unit || entry.unit,
            duration_minutes: previous.duration_minutes || entry.duration_minutes
          )
        end
      end
    end
  end

  def canonical_name(name)
    name = name.squish.truncate(60, omission: "").strip

    if name.downcase.match?(OXYGEN)
      "Oxygen"
    else
      name.upcase_first
    end
  end

  private
    def parse_mention(mention)
      text = mention.squish
      return if text.blank?

      duration_minutes = extract(text, DURATION) { |match| match[:minutes].to_i }
      amount, unit = extract(text, AMOUNT_WITH_UNIT) { |match| [ match[:amount].to_d, match[:unit].downcase ] } ||
        extract(text, BARE_AMOUNT) { |match| [ match[:amount].to_d, nil ] }

      name = text.gsub(/[()\[\]{}:]/, " ").squish.delete_prefix("-").delete_suffix("-").squish
      return if name.match?(NOTHING)

      name = canonical_name(name) if name.present?

      Entry.new(name: name, amount: amount, unit: unit_for(unit, name), duration_minutes: duration_minutes&.positive? ? duration_minutes : nil)
    end

    def extract(text, pattern)
      if match = text.match(pattern)
        text.sub!(match[0], " ")
        yield match
      end
    end

    def unit_for(unit, name)
      if unit == "l" && name != "Oxygen"
        "L"
      elsif unit
        UNITS.fetch(unit, unit)
      end
    end
end
