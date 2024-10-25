# app/helpers/icon_helper.rb
module IconHelper
  include ActionView::Helpers::TagHelper

  # Renders an SVG icon from app/assets/images/icons/
  #
  # @example Basic usage
  #   <%= icon "github" %>
  #
  # @example With styling
  #   <%= icon "github", class: "w-6 h-6 text-gray-500" %>
  #
  # @example With additional attributes
  #   <%= icon "github", data: { controller: "tooltip" } %>
  #
  # Note: SVG files should have `fill="currentColor"` to support dynamic coloring
  def icon(name, **options)
    path = Rails.root.join("app/assets/images/icons/#{name}.svg")
    svg = File.read(path)

    options[:class] = [ "icon", options[:class] ].compact.join(" ")
    svg.sub("<svg", "<svg aria-hidden=\"true\" #{html_attributes(options)}").html_safe
  rescue Errno::ENOENT => e
    Rails.logger.error "Icon not found: #{name}"
    nil
  end

  private

  def html_attributes(attributes)
    attributes.map { |k, v| %(#{k.to_s.tr('_', '-')}="#{v}") }.join(" ")
  end
end
