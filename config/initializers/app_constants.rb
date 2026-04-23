# Application constants
module AppConstants
  CHANGELOG_KEY = "2026-04-fresh-look"
  GITHUB_API_BASE_URL = "https://api.github.com"
  ANDROID_GITHUB_REPOSITORY = "crmne/cluster-headache-tracker-android"
  IOS_GITHUB_REPOSITORY = "crmne/cluster-headache-tracker-ios"
  ANDROID_APK_URL = "https://github.com/#{ANDROID_GITHUB_REPOSITORY}/releases/latest/download/cluster-headache-tracker.apk"
  IOS_APP_STORE_URL = ENV["IOS_APP_STORE_URL"]
end
