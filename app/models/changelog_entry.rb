class ChangelogEntry
  attr_reader :highlight_description, :highlight_icon, :highlight_title, :key,
    :legacy_keys, :note_body, :note_title, :share_label, :share_text,
    :share_title, :share_url, :support_label, :support_url, :title,
    :version_label

  def self.current
    find(AppConstants::CHANGELOG_KEY)
  end

  def self.find(key)
    if attributes = entries[key]
      new(key:, attributes:)
    else
      raise KeyError, "Unknown changelog entry: #{key}"
    end
  end

  def initialize(key:, attributes:)
    @key = key
    @legacy_keys = Array(attributes["legacy_keys"])
    @title = attributes.fetch("title")
    @version_label = attributes.fetch("version_label")
    @highlight_icon = attributes.fetch("highlight_icon")
    @highlight_title = attributes.fetch("highlight_title")
    @highlight_description = attributes.fetch("highlight_description")
    @note_title = attributes.fetch("note_title")
    @note_body = attributes.fetch("note_body")
    @share_url = attributes.fetch("share_url")
    @share_title = attributes.fetch("share_title")
    @share_text = attributes.fetch("share_text")
    @share_label = attributes.fetch("share_label")
    @support_url = attributes.fetch("support_url")
    @support_label = attributes.fetch("support_label")
  end

  def seen_by?(user)
    if user.last_seen_changelog.present?
      seen_keys.include?(user.last_seen_changelog)
    else
      false
    end
  end

  def seen_keys
    [ key ] + legacy_keys
  end

  class << self
    private
      def entries
        YAML.safe_load(Rails.root.join("config/changelog_entries.yml").read, aliases: true).fetch("entries")
      end
  end
end
