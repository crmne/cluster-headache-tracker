# Renders SVG icons from app/assets/images/icons/
#
#   <%= icon "github" %>
#   <%= icon "github", class: "w-6 h-6 text-gray-500" %>
#   <%= icon "github", data: { controller: "tooltip" } %>
#
# Note: SVG files should have `fill="currentColor"` to support dynamic coloring
module IconHelper
  def icon(name, **options)
    svg = Rails.root.join("app/assets/images/icons/#{name}.svg").read
    options[:class] = [ "icon", options[:class] ].compact.join(" ")
    svg.sub("<svg", %(<svg aria-hidden="true" #{tag.attributes(options)})).html_safe
  end
end
