class HeadacheLogs::PhotosController < ApplicationController
  include HeadacheLogScoped

  before_action :set_photo

  def show
  end

  def destroy
    @photo.purge_later

    redirect_to edit_headache_log_path(@headache_log), notice: t("photos.removed"), status: :see_other
  end

  private
    def set_photo
      @photo = @headache_log.photos.find(params[:id])
    end
end
