class AddLastSeenChangelogToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_seen_changelog, :string
  end
end
