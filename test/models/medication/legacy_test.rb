require "test_helper"

class Medication::LegacyTest < ActiveSupport::TestCase
  test "splits mentions on commas, plus signs, ampersands, semicolons and 'and'" do
    assert_equal %w[ Sumatriptan Oxygen Verapamil Lithium Melatonin ],
      names("sumatriptan + oxygen, verapamil; lithium and melatonin")
  end

  test "reads doses, units and oxygen durations" do
    oxygen, sumatriptan, emgality = Medication::Legacy.parse("oxygen 15 l/min 20 min, sumatriptan 6mg, emgality 120 mg")

    assert_equal [ "Oxygen", 15, "L/min", 20 ], oxygen.to_h.values_at(:name, :amount, :unit, :duration_minutes)
    assert_equal [ "Sumatriptan", 6, "mg", nil ], sumatriptan.to_h.values_at(:name, :amount, :unit, :duration_minutes)
    assert_equal [ "Emgality", 120, "mg" ], emgality.to_h.values_at(:name, :amount, :unit)
  end

  test "reads the sample report's 'oxygen 15 min' as a duration" do
    entry = Medication::Legacy.parse("oxygen 15 min").sole

    assert_equal "Oxygen", entry.name
    assert_nil entry.amount
    assert_equal 15, entry.duration_minutes
  end

  test "recognises oxygen synonyms and normalises units" do
    assert_equal %w[ Oxygen Oxygen Oxygen ], names("O2, Sauerstoff, ossigeno")
    assert_equal "L/min", Medication::Legacy.parse("o2 12 lpm").sole.unit
    assert_equal "mcg", Medication::Legacy.parse("fentanyl 50 µg").sole.unit
    assert_equal "tablets", Medication::Legacy.parse("ibuprofen 2 tabs").sole.unit
  end

  test "keeps a unitless number as the amount so the text reads back the same" do
    entry = Medication::Legacy.parse("sumatriptan 6").sole

    assert_equal "Sumatriptan", entry.name
    assert_equal 6, entry.amount
    assert_nil entry.unit
  end

  test "a bare dose belongs to the medication before it" do
    entry = Medication::Legacy.parse("oxygen, 15 min").sole

    assert_equal "Oxygen", entry.name
    assert_equal 15, entry.duration_minutes
  end

  test "ignores blanks and 'none'" do
    assert_empty Medication::Legacy.parse(nil)
    assert_empty Medication::Legacy.parse(" , ,")
    assert_empty Medication::Legacy.parse("none")
    assert_equal %w[ Oxygen ], names("n/a, oxygen")
  end

  test "reads back the labels doses write" do
    log = headache_logs(:three)

    assert_equal log.medication_doses.map(&:label).map(&:downcase),
      Medication::Legacy.parse(log.medication_doses.map(&:label).join(", ")).map { |entry| label_for(entry) }
  end

  private
    def names(text)
      Medication::Legacy.parse(text).map(&:name)
    end

    def label_for(entry)
      [ entry.name, entry.amount && [ MedicationDose.format_amount(entry.amount), entry.unit ].compact.join(" "),
        entry.duration_minutes && "#{entry.duration_minutes} min" ].compact.join(" ").downcase
    end
end
