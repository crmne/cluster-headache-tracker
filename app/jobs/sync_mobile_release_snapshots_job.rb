class SyncMobileReleaseSnapshotsJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform
    MobileReleaseSnapshot.sync_all
  end
end
