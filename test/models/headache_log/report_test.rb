require "test_helper"

class HeadacheLog::ReportTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.headache_logs.destroy_all

    @first = log_attack at: "2026-09-01 02:10", minutes: 45, intensity: 8, medication: "Oxygen", triggers: "Alcohol"
    @second = log_attack at: "2026-09-01 22:30", minutes: 90, intensity: 10, medication: "Oxygen, Sumatriptan", triggers: "Alcohol, Sleep"
    @third = log_attack at: "2026-09-04 03:00", minutes: nil, intensity: 6, notes: "Rechtes Auge, Tränenfluss 😣"
  end

  test "summarizes attacks" do
    report = @user.headache_logs.report

    assert_equal 3, report.attack_count
    assert_equal 2, report.attack_days
    assert_equal 8.0, report.average_intensity
    assert_equal 10, report.max_intensity
    assert_equal 67.5.minutes, report.average_duration
    assert_equal Date.new(2026, 9, 1)..Date.new(2026, 9, 4), report.period
  end

  test "counts attacks per day across the whole period" do
    attacks_per_day = @user.headache_logs.report.attacks_per_day

    assert_equal [ 2, 0, 0, 1 ], attacks_per_day.values
  end

  test "groups attacks by two hour time of day buckets" do
    buckets = @user.headache_logs.report.attacks_by_time_of_day

    assert_equal 12, buckets.size
    assert_equal 2, buckets[1]
    assert_equal 1, buckets[11]
    assert_equal 3, buckets.sum
  end

  test "summarizes medication and trigger use" do
    report = @user.headache_logs.report
    oxygen, sumatriptan = report.medication_usage

    assert_equal [ "oxygen", 2, 67.5.minutes ], [ oxygen.name, oxygen.attacks, oxygen.average_duration ]
    assert_equal [ "sumatriptan", 1, 90.minutes ], [ sumatriptan.name, sumatriptan.attacks, sumatriptan.average_duration ]
    assert_equal [ [ "Alcohol", 2 ], [ "Sleep", 1 ] ], report.trigger_counts
  end

  test "uses filter dates as the period" do
    report = @user.headache_logs.report(filters: { start_time: "2026-08-15", end_time: "2026-09-30" })

    assert_equal Date.new(2026, 8, 15)..Date.new(2026, 9, 30), report.period
  end

  test "has no period without attacks or filters" do
    assert_nil HeadacheLog.none.report.period
  end

  test "cleans up the optional name fields" do
    report = HeadacheLog.none.report(patient_name: "  Alex   Smith ", prepared_for: "")

    assert_equal "Alex Smith", report.patient_name
    assert_nil report.prepared_for
  end

  test "renders a pdf with every section" do
    text = pdf_text(@user.headache_logs.report(patient_name: "Alex Smith", prepared_for: "Dr. Jones").to_pdf)

    assert_includes text, "Cluster Headache Report"
    assert_includes text, "Alex Smith"
    assert_includes text, "Dr. Jones"
    assert_includes text, "Sep 1, 2026 – Sep 4, 2026"
    assert_includes text, "8/10"
    assert_includes text, "1 h 8 min"
    assert_includes text, "Attacks per day"
    assert_includes text, "Attacks by time of day"
    assert_includes text, "Medication and treatment"
    assert_includes text, "sumatriptan"
    assert_includes text, "Reported triggers"
    assert_includes text, "Attack log"
    assert_includes text, "3:00 AM –"
    assert_includes text, "ongoing"
    assert_includes text, "Rechtes Auge, Tränenfluss"
  end

  test "renders a pdf in german" do
    text = I18n.with_locale(:de) { pdf_text(@user.headache_logs.report.to_pdf) }

    assert_includes text, "Clusterkopfschmerz-Bericht"
    assert_includes text, "01.09.2026 – 04.09.2026"
    assert_includes text, "Höchste Intensität"
    assert_includes text, "andauernd"
  end

  test "renders a pdf in italian and spanish" do
    assert_includes I18n.with_locale(:it) { pdf_text(@user.headache_logs.report.to_pdf) }, "Intensità massima"
    assert_includes I18n.with_locale(:es) { pdf_text(@user.headache_logs.report.to_pdf) }, "Duración media"
  end

  test "renders a pdf without attacks" do
    text = pdf_text(HeadacheLog.none.report.to_pdf)

    assert_includes text, "No attacks recorded in this period."
    assert_not_includes text, "Attack log"
  end

  test "names the file after the report" do
    assert_equal "cluster-headache-report-#{Date.current.iso8601}.pdf", HeadacheLog.none.report.filename
  end

  private
    def log_attack(at:, minutes:, intensity:, **attributes)
      start_time = Time.zone.parse(at)

      @user.headache_logs.create!(start_time: start_time, end_time: minutes && start_time + minutes.minutes, intensity: intensity, **attributes)
    end
end
