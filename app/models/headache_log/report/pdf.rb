require "prawn/table"

class HeadacheLog::Report::Pdf
  include Prawn::View

  FONTS = Rails.root.join("vendor/fonts")

  INK = "111827"
  MUTED = "6B7280"
  RULE = "D1D5DB"
  PANEL = "F3F4F6"
  ACCENT = "4F46E5"

  CHART_HEIGHT = 150
  GUTTER = 16

  attr_reader :report

  def initialize(report)
    @report = report
  end

  def document
    @document ||= Prawn::Document.new(page_size: "A4", margin: [ 40, 40, 56, 40 ], info: { Title: t("title"), Creator: "Cluster Headache Tracker" })
  end

  def render
    use_embedded_font
    header
    summary

    if report.attack_count.positive?
      patterns
      medication_usage
      triggers
      attack_log
    else
      text t("attacks.none"), size: 10, color: MUTED
    end

    footer
    document.render
  end

  private
    def use_embedded_font
      font_families.update("Noto Sans" => { normal: FONTS.join("NotoSans-Regular.ttf").to_s, bold: FONTS.join("NotoSans-Bold.ttf").to_s })
      font "Noto Sans"
      fill_color INK
    end

    def header
      text t("title"), size: 20, style: :bold
      move_down 6

      header_details.each do |label, value|
        formatted_text [ { text: "#{label}: ", styles: [ :bold ] }, { text: value } ], size: 9.5, leading: 2
      end

      move_down 6
      text t("disclaimer"), size: 7.5, color: MUTED
      move_down 10
      horizontal_rule_with_space
    end

    def header_details
      [
        [ t("patient"), printable(report.patient_name).presence ],
        [ t("prepared_for"), printable(report.prepared_for).presence ],
        [ t("period"), period_description ],
        [ t("filters.label"), filter_description ],
        [ t("generated"), I18n.l(Time.current, format: :pdf_report_generated) ]
      ].select(&:last)
    end

    def period_description
      if period = report.period
        t("period_range", from: l(period.first), to: l(period.last))
      end
    end

    def filter_description
      descriptions = report.filters.slice(:triggers, :medication).map { |key, value| t("filters.#{key}", value: value) }
      descriptions.join(", ").presence
    end

    def summary
      section t("summary.heading")
      boxes = summary_figures
      box_width = (bounds.width - GUTTER / 2 * (boxes.size - 1)) / boxes.size
      top = cursor

      boxes.each_with_index do |(label, value), index|
        bounding_box([ index * (box_width + GUTTER / 2), top ], width: box_width, height: 58) do
          fill_color PANEL
          fill_rounded_rectangle [ 0, bounds.top ], bounds.width, bounds.height, 4
          fill_color INK

          text_box value, at: [ 8, bounds.top - 8 ], width: bounds.width - 16, height: 22, size: 16, style: :bold, overflow: :shrink_to_fit
          text_box label, at: [ 8, bounds.top - 32 ], width: bounds.width - 16, height: 20, size: 7.5, color: MUTED, overflow: :shrink_to_fit
        end
      end

      move_cursor_to top - 58
      move_down 18
    end

    def summary_figures
      [
        [ t("summary.attacks"), report.attack_count.to_s ],
        [ t("summary.attack_days"), report.attack_days.to_s ],
        [ t("summary.average_intensity"), intensity(report.average_intensity) ],
        [ t("summary.max_intensity"), intensity(report.max_intensity) ],
        [ t("summary.average_duration"), duration(report.average_duration) ]
      ]
    end

    def patterns
      section t("charts.heading"), keep_with: CHART_HEIGHT * 2 + GUTTER

      attacks_per_day = report.attacks_per_day
      Chart.new(document, at: [ 0, cursor ], width: bounds.width, height: CHART_HEIGHT, title: t("charts.attacks_per_day"))
        .bars(attacks_per_day.values, labels: date_labels(attacks_per_day.keys))
      move_down GUTTER

      top = cursor
      half = (bounds.width - GUTTER) / 2

      Chart.new(document, at: [ 0, top ], width: half, height: CHART_HEIGHT, title: t("charts.time_of_day"))
        .bars(report.attacks_by_time_of_day, labels: time_of_day_labels)
      Chart.new(document, at: [ half + GUTTER, top ], width: half, height: CHART_HEIGHT, title: t("charts.intensity_over_time"))
        .dots(intensity_points, labels: date_labels(report.period.to_a, count: 4))

      move_cursor_to top - CHART_HEIGHT
      move_down 18
    end

    def date_labels(days, count: 6)
      step = [ (days.size / count.to_f).ceil, 1 ].max

      0.step(days.size - 1, step).to_h { |index| [ (index + 0.5) / days.size, l(days[index], format: :pdf_report_short) ] }
    end

    def time_of_day_labels
      report.attacks_by_time_of_day.each_index.to_h do |index|
        [ (index + 0.5) / report.attacks_by_time_of_day.size, format("%02d", index * HeadacheLog::Report::TIME_OF_DAY_BUCKET_HOURS) ]
      end
    end

    def intensity_points
      first_moment = report.period.first.beginning_of_day
      span = report.period.last.end_of_day - first_moment

      report.headache_logs.map { |log| [ ((log.start_time - first_moment) / span).clamp(0.0, 1.0), log.intensity ] }
    end

    def medication_usage
      section t("medication.heading"), keep_with: 60

      if (usages = report.medication_usage).any?
        rows = usages.map do |usage|
          [ printable(usage.name), usage.attacks.to_s, percentage(usage.attacks), duration(usage.average_duration) ]
        end

        summary_table [ [ t("medication.name"), t("medication.attacks"), t("medication.share"), t("medication.average_duration") ], *rows ]
      else
        text t("medication.none"), size: 9, color: MUTED
      end

      move_down 18
    end

    def triggers
      section t("triggers.heading"), keep_with: 60

      if (trigger_counts = report.trigger_counts).any?
        rows = trigger_counts.map { |trigger, count| [ printable(trigger), count.to_s, percentage(count) ] }

        summary_table [ [ t("triggers.name"), t("triggers.attacks"), t("medication.share") ], *rows ]
      else
        text t("triggers.none"), size: 9, color: MUTED
      end

      move_down 18
    end

    def summary_table(rows)
      table rows, header: true, width: bounds.width, cell_style: table_cell_style do |table|
        table.row(0).font_style = :bold
        table.row(0).background_color = PANEL
        table.columns(1..-1).align = :right
      end
    end

    def attack_log
      section t("attacks.heading"), keep_with: 60

      rows = report.headache_logs.map do |log|
        [ l(log.start_time.to_date), attack_time(log), duration(log.duration), "#{log.intensity}/10", printable(log.medication), printable(log.triggers), printable(log.notes) ]
      end

      headings = %w[ date time duration intensity medication triggers notes ].map { |column| t("attacks.#{column}") }

      table [ headings, *rows ], header: true, width: bounds.width, column_widths: { 0 => 56, 1 => 80, 2 => 50, 3 => 54, 4 => 72, 5 => 66 },
        cell_style: table_cell_style.merge(size: 7.5) do |table|
        table.row(0).font_style = :bold
        table.row(0).background_color = PANEL
      end
    end

    def attack_time(log)
      ending = log.end_time ? I18n.l(log.end_time, format: :pdf_report_time) : t("attacks.ongoing")

      "#{I18n.l(log.start_time, format: :pdf_report_time)} – #{ending}"
    end

    def table_cell_style
      { size: 8.5, padding: [ 4, 5 ], borders: [ :bottom ], border_color: RULE, border_width: 0.5, text_color: INK }
    end

    def footer
      number_pages t("page_number"), at: [ bounds.right - 120, -18 ], width: 120, align: :right, size: 7.5, color: MUTED
      number_pages footer_label, at: [ 0, -18 ], width: bounds.width - 130, size: 7.5, color: MUTED
    end

    def footer_label
      [ t("title"), printable(report.patient_name).presence, "clusterheadachetracker.com" ].compact.join(" · ")
    end

    def section(title, keep_with: 0)
      start_new_page if cursor < keep_with + 30
      text title, size: 12, style: :bold
      move_down 8
    end

    def horizontal_rule_with_space
      stroke_color RULE
      line_width 0.5
      stroke_horizontal_rule
      move_down 16
    end

    # Drops characters the embedded font has no glyph for (emoji, mostly)
    # instead of printing empty boxes.
    def printable(value)
      value.to_s.each_char.select { |character| character.match?(/\s/) || font.glyph_present?(character) }.join
    end

    def intensity(value)
      if value
        t("summary.out_of_ten", value: ActiveSupport::NumberHelper.number_to_rounded(value, precision: 1, strip_insignificant_zeros: true))
      else
        t("not_available")
      end
    end

    def duration(seconds)
      if seconds
        minutes = (seconds / 60).round
        hours, minutes = minutes.divmod(60)

        hours.positive? ? t("duration.hours_minutes", hours: hours, minutes: minutes) : t("duration.minutes", minutes: minutes)
      else
        t("not_available")
      end
    end

    def percentage(count)
      ActiveSupport::NumberHelper.number_to_percentage(count * 100.0 / report.attack_count, precision: 0)
    end

    def l(date, format: :pdf_report)
      I18n.l(date, format: format)
    end

    def t(key, **options)
      I18n.t(key, scope: :pdf_reports, **options)
    end
end
