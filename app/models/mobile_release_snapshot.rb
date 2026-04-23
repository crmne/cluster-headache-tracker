class MobileReleaseSnapshot < ApplicationRecord
  PLATFORMS = %w[android ios].freeze

  validates :platform, presence: true, inclusion: { in: PLATFORMS }, uniqueness: true

  def self.for_platform(platform)
    if platform.present?
      find_by(platform:)
    end
  end

  def update_available_for?(version)
    newer_than?(latest_version, version)
  end

  def update_required_for?(version)
    newer_than?(minimum_supported_version, version)
  end

  private
    def newer_than?(candidate_version, current_version)
      if candidate_version.present? && current_version.present?
        Gem::Version.new(candidate_version) > Gem::Version.new(current_version)
      else
        false
      end
    rescue ArgumentError
      false
    end
end
