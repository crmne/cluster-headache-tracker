class SyncMobileReleaseSnapshotsJob < ApplicationJob
  queue_as :default

  def perform
    MobileReleaseSnapshot.sync_all
  end
end
