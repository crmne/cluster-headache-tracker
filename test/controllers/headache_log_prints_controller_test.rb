require "test_helper"

class HeadacheLogPrintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "shows the print report with a pdf download" do
    get headache_log_print_url(start_time: Date.yesterday.iso8601)

    assert_response :success
    assert_select "dialog#pdf_report_modal form[action=?][method=get]", headache_log_print_path(format: :pdf) do
      assert_select "input[type=hidden][name=start_time][value=?]", Date.yesterday.iso8601
      assert_select "input[name=patient_name]"
      assert_select "input[name=prepared_for]"
    end
  end

  test "downloads the report as a pdf" do
    get headache_log_print_url(format: :pdf, patient_name: "Alex Smith", prepared_for: "Dr. Jones")

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_match(/attachment; filename="cluster-headache-report-#{Date.current.iso8601}\.pdf"/, response.headers["Content-Disposition"])
    assert_includes response.headers["Cache-Control"], "no-store"

    text = pdf_text(response.body)
    assert_includes text, "Alex Smith"
    assert_includes text, "Dr. Jones"
    assert_includes text, "Zolmitriptan"
  end

  test "includes only the current user's attacks" do
    get headache_log_print_url(format: :pdf)

    text = pdf_text(response.body)
    assert_includes text, "Sleeping"
    assert_not_includes text, "Waking up"
  end

  test "respects the filters" do
    get headache_log_print_url(format: :pdf, medication: "zolmi")

    text = pdf_text(response.body)
    assert_includes text, "medication containing “zolmi”"
    assert_includes text, "Zolmitriptan"
    assert_not_includes text, "Sumatriptan + Oxygen"
  end

  test "respects the date range" do
    get headache_log_print_url(format: :pdf, start_time: Date.current.iso8601, end_time: Date.tomorrow.iso8601)

    text = pdf_text(response.body)
    assert_includes text, I18n.l(Date.current, format: :pdf_report)
    assert_not_includes text, I18n.l(headache_logs(:three).start_time.to_date, format: :pdf_report)
  end

  test "renders the pdf in the requested locale" do
    get headache_log_print_url(format: :pdf, locale: :de)

    assert_includes pdf_text(response.body), "Clusterkopfschmerz-Bericht"
    assert_match(/clusterkopfschmerz-bericht-/, response.headers["Content-Disposition"])
  end

  test "requires authentication for the pdf" do
    sign_out @user

    get headache_log_print_url(format: :pdf)

    assert_response :unauthorized
  end

  test "print report includes streaks and cycles" do
    get headache_log_print_url

    assert_response :success
    assert_select "#attack_streaks"
    assert_select "#cycles #attack_calendar"
    assert_select "#cycles_table tbody tr", count: 1
  end
end
