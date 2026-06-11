class Users::ChangelogAcknowledgementsController < ApplicationController
  before_action :authenticate_user!

  def create
    changelog_key = params[:key].presence || params[:version].presence
    if changelog_key.present? && current_user.update(last_seen_changelog: changelog_key)
      respond_to do |format|
        format.json { head :ok }
        format.html { redirect_back fallback_location: headache_logs_path }
      end
    else
      respond_to do |format|
        format.json { head :unprocessable_entity }
        format.html { redirect_back fallback_location: headache_logs_path, alert: "Couldn't dismiss changelog." }
      end
    end
  end
end
