class HeadacheLogs::Photos::VariantsController < ApplicationController
  include HeadacheLogScoped

  def show
    photo = @headache_log.photos.find(params[:photo_id])
    variant = photo.variant(params[:id].to_sym).processed

    # Medical photos shouldn't linger in browser or proxy caches after sign-out.
    response.cache_control.replace(no_store: true)

    send_data variant.download, type: variant.variation.content_type, disposition: :inline,
      filename: "#{photo.filename.base}.#{variant.variation.format}"
  end
end
