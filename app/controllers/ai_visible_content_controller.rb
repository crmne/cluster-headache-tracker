class AiVisibleContentController < ApplicationController
  before_action :set_public_cache_headers

  def llms
    render plain: AiVisibleContent.llms_txt, content_type: "text/plain; charset=utf-8"
  end

  def llms_full
    render plain: AiVisibleContent.llms_full_txt, content_type: "text/plain; charset=utf-8"
  end

  def llm
    render json: AiVisibleContent.llm_json
  end

  def entity_map
    render json: AiVisibleContent.entity_map
  end

  def resource
    if data = AiVisibleContent.resource(params[:resource_type], params[:slug])
      render_resource(data)
    else
      render_not_found
    end
  end

  private
    def set_public_cache_headers
      expires_in 1.hour, public: true
      response.set_header("X-Robots-Tag", "index, follow, max-image-preview:large")
    end

    def render_resource(data)
      case params[:format]
      when "md", "txt"
        render_markdown_resource
      when "yml", "yaml"
        render plain: data.to_yaml, content_type: "application/x-yaml; charset=utf-8"
      else
        render json: data
      end
    end

    def render_markdown_resource
      if params[:resource_type] == "page" && (markdown = AiVisibleContent.page_markdown(params[:slug]))
        render plain: markdown, content_type: "text/markdown; charset=utf-8"
      else
        render_not_found
      end
    end

    def render_not_found
      render plain: "Not found", status: :not_found
    end
end
