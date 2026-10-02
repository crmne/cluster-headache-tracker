# Draws a small vector chart into a Prawn document. Horizontal positions
# are fractions of the plot width (0.0 left edge, 1.0 right edge), so the
# same labels work for bars and for points placed along a date range.
class HeadacheLog::Report::Pdf::Chart
  AXIS_WIDTH = 20
  LABEL_HEIGHT = 12
  TITLE_HEIGHT = 16

  INK = HeadacheLog::Report::Pdf::INK
  MUTED = HeadacheLog::Report::Pdf::MUTED
  RULE = HeadacheLog::Report::Pdf::RULE
  ACCENT = HeadacheLog::Report::Pdf::ACCENT

  attr_reader :pdf, :at, :width, :height, :title

  def initialize(pdf, at:, width:, height:, title:)
    @pdf, @at, @width, @height, @title = pdf, at, width, height, title
  end

  def bars(values, labels:)
    draw(maximum: nice_maximum(values.max.to_i), labels: labels) do |plot_width, plot_height, maximum|
      slot = plot_width / values.size
      gap = slot > 4 ? slot * 0.2 : 0

      values.each_with_index do |value, index|
        if value.positive?
          bar_height = plot_height * value / maximum
          pdf.fill_rectangle [ slot * index + gap / 2, bar_height ], [ slot - gap, 0.6 ].max, bar_height
        end
      end
    end
  end

  def dots(points, labels:)
    draw(maximum: 10, labels: labels) do |plot_width, plot_height, maximum|
      points.each do |position, value|
        pdf.fill_circle [ plot_width * position, plot_height * value / maximum ], 2.2
      end
    end
  end

  private
    def draw(maximum:, labels:)
      pdf.bounding_box(at, width: width, height: height) do
        pdf.text title, size: 9, style: :bold, color: INK

        plot_width = width - AXIS_WIDTH
        plot_height = height - TITLE_HEIGHT - LABEL_HEIGHT

        pdf.bounding_box([ AXIS_WIDTH, plot_height + LABEL_HEIGHT ], width: plot_width, height: plot_height) do
          grid(plot_width, plot_height, maximum)
          x_labels(plot_width, labels)

          pdf.fill_color ACCENT
          yield plot_width, plot_height, maximum
          pdf.fill_color INK
        end
      end
    end

    def grid(plot_width, plot_height, maximum)
      step = tick_step(maximum)

      pdf.line_width 0.4
      pdf.stroke_color RULE

      0.step(maximum, step) do |tick|
        y = plot_height * tick / maximum
        pdf.stroke_horizontal_line 0, plot_width, at: y
        pdf.text_box tick.to_s, at: [ -AXIS_WIDTH, y + 4 ], width: AXIS_WIDTH - 4, height: 10, align: :right, size: 6.5, color: MUTED
      end
    end

    def x_labels(plot_width, labels)
      labels.each do |position, label|
        pdf.text_box label, at: [ plot_width * position - 25, -3 ], width: 50, height: 10, align: :center, size: 6.5, color: MUTED
      end
    end

    def nice_maximum(value)
      step = tick_step(value)

      [ (value.to_f / step).ceil * step, step ].max
    end

    def tick_step(value)
      rough_step = value / 5.0
      magnitude = 10**[ Math.log10([ rough_step, 1 ].max).floor, 0 ].max

      [ 1, 2, 5, 10 ].map { |multiple| multiple * magnitude }.find { |step| step >= rough_step }
    end
end
