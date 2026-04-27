require "json"
require "net/http"

class SyncMobileReleaseSnapshotsJob < ApplicationJob
  ANDROID_APK_ASSET_NAME = "cluster-headache-tracker.apk"

  queue_as :default

  def perform
    sync_platform(platform: "android", repository: AppConstants::ANDROID_GITHUB_REPOSITORY)
    sync_platform(
      platform: "ios",
      repository: AppConstants::IOS_GITHUB_REPOSITORY,
      fallback_release_url: AppConstants::IOS_APP_STORE_URL.presence
    )
  end

  private
    def sync_platform(platform:, repository:, fallback_release_url: nil)
      if metadata = fetch_metadata_for(repository:, fallback_release_url:)
        snapshot = MobileReleaseSnapshot.find_or_initialize_by(platform:)
        snapshot.update!(
          latest_version: metadata[:latest_version],
          release_url: metadata[:release_url],
          release_notes_url: metadata[:release_notes_url],
          source: metadata[:source],
          fetched_at: Time.current
        )
      end
    rescue StandardError => error
      Rails.logger.error("Failed to sync #{platform} release metadata: #{error.class} #{error.message}")
    end

    def fetch_metadata_for(repository:, fallback_release_url:)
      if release = github_json(repository:, path: "/releases/latest")
        metadata_from_release(release:, fallback_release_url:)
      elsif tag = github_json(repository:, path: "/tags?per_page=1")&.first
        metadata_from_tag(repository:, tag:, fallback_release_url:)
      end
    end

    def metadata_from_release(release:, fallback_release_url:)
      tag_name = release.fetch("tag_name")

      {
        latest_version: normalize_version(tag_name),
        release_url: release_asset_url(release) || fallback_release_url || release["html_url"],
        release_notes_url: release["html_url"],
        source: "github_release"
      }
    end

    def metadata_from_tag(repository:, tag:, fallback_release_url:)
      tag_name = tag.fetch("name")

      {
        latest_version: normalize_version(tag_name),
        release_url: fallback_release_url,
        release_notes_url: "https://github.com/#{repository}/tree/#{tag_name}",
        source: "github_tag"
      }
    end

    def release_asset_url(release)
      assets = Array(release["assets"])
      apk_asset = assets.find { |asset| asset["name"].to_s == ANDROID_APK_ASSET_NAME }
      apk_asset ||= assets.find do |asset|
        asset["name"].to_s.end_with?(".apk") && !asset["name"].to_s.match?(/debug/i)
      end

      if apk_asset
        apk_asset["browser_download_url"]
      end
    end

    def normalize_version(tag_name)
      tag_name.delete_prefix("v")
    end

    def github_json(repository:, path:)
      uri = URI("#{AppConstants::GITHUB_API_BASE_URL}/repos/#{repository}#{path}")
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/vnd.github+json"
      request["User-Agent"] = "ClusterHeadacheTracker Release Sync"

      if github_api_token = ENV["GITHUB_API_TOKEN"].presence
        request["Authorization"] = "Bearer #{github_api_token}"
      end

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
      elsif response.is_a?(Net::HTTPNotFound)
        nil
      else
        raise "GitHub API returned #{response.code} for #{uri}"
      end
    end
end
