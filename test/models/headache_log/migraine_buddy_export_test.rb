require "test_helper"

class HeadacheLog::MigraineBuddyExportTest < ActiveSupport::TestCase
  test "recognizes a Migraine Buddy export by its attack header row" do
    assert_instance_of HeadacheLog::MigraineBuddyExport, parse("migraine_buddy_sample.csv")
  end

  test "does not recognize the app's own CSV export" do
    assert_nil parse("sample_logs.csv")
  end

  test "does not recognize a file without the attack header row" do
    assert_nil HeadacheLog::MigraineBuddyExport.parse(<<~CSV)
      "Date","Time Period","Description","Notes"
      "No ongoing events recorded during this period.","","",""
    CSV
  end

  test "maps the contributed sample" do
    attributes = parse("migraine_buddy_sample.csv").log_attributes

    assert_equal 1, attributes.size
    assert_equal(
      {
        start_time: Time.zone.parse("2024-11-16 13:12 UTC"),
        end_time: Time.zone.parse("2024-11-16 14:12 UTC"),
        intensity: 4,
        medication: "",
        triggers: "Stress",
        notes: "Symptoms: Sensitivity to light, Throbbing pain\nPain Positions: Right Back of Head (Lower), Left Back of Head (Lower)"
      },
      attributes.first
    )
  end

  test "shifts the local start time by the start UTC offset" do
    attributes = mixed_attributes

    assert_equal Time.zone.parse("2024-11-16 12:12 UTC"), attributes[0][:start_time]
    assert_equal Time.zone.parse("2024-11-17 07:05 UTC"), attributes[1][:start_time]
  end

  test "ends attacks after the duration they lasted" do
    attributes = mixed_attributes

    assert_equal 1.hour, attributes[0][:end_time] - attributes[0][:start_time]
    assert_equal 45.minutes, attributes[1][:end_time] - attributes[1][:start_time]
    assert_equal 1.day + 2.hours + 15.minutes, attributes[2][:end_time] - attributes[2][:start_time]
  end

  test "leaves the end time open when the duration is missing" do
    assert_nil mixed_attributes[5][:end_time]
  end

  test "lifts a pain level of zero to the lowest intensity" do
    assert_equal 9, mixed_attributes[0][:intensity]
    assert_equal 1, mixed_attributes[1][:intensity]
  end

  test "leaves the intensity empty when the pain level is missing" do
    assert_nil mixed_attributes[4][:intensity]
  end

  test "combines every medication column and ignores no medication" do
    assert_equal "Oxygen, Sumatriptan, Ibuprofen", mixed_attributes[0][:medication]
    assert_equal "", mixed_attributes[1][:medication]
    assert_equal "Zolmitriptan, Oxygen", mixed_attributes[2][:medication]
  end

  test "keeps potential triggers" do
    assert_equal "Alcohol, Sleep", mixed_attributes[0][:triggers]
    assert_equal "Weather", mixed_attributes[2][:triggers]
  end

  test "puts notes first and the remaining details below them" do
    assert_equal <<~NOTES.chomp, mixed_attributes[0][:notes]
      Woke me up at night,
      second one this week

      Attack Types: Cluster headache
      Attack Location: Home
      Affected Activities: Sleep
      Symptoms: Tearing eye, Restlessness
      Most Bothersome Symptom: Restlessness
      Premonitory Symptoms: Yawning
      Pain Positions: Right Eye
      Helpful Medication: Oxygen
      Somewhat Helpful Medication: Sumatriptan
      Unhelpful Medication: Ibuprofen
      Helpful Non Drug Relief Methods: Cold shower
      Unhelpful Non Drug Relief Methods: Pacing
    NOTES
  end

  test "never imports the location geohash" do
    assert mixed_attributes.compact.none? { |attributes| attributes[:notes].include?("u0yjjd") }
  end

  test "leaves notes empty when a row has nothing more to say" do
    assert_equal "", mixed_attributes[1][:notes]
  end

  test "returns nil for rows whose start can't be read" do
    assert_nil mixed_attributes[3]
  end

  test "skips blank rows" do
    assert_equal 7, mixed_attributes.size
  end

  private
    def parse(fixture)
      HeadacheLog::MigraineBuddyExport.parse(file_fixture(fixture).read)
    end

    def mixed_attributes
      parse("migraine_buddy_mixed.csv").log_attributes
    end
end
