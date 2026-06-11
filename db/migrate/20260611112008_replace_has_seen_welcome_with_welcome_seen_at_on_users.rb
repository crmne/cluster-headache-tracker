class ReplaceHasSeenWelcomeWithWelcomeSeenAtOnUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :welcome_seen_at, :datetime
    execute "UPDATE users SET welcome_seen_at = updated_at WHERE has_seen_welcome"
    remove_column :users, :has_seen_welcome
  end

  def down
    add_column :users, :has_seen_welcome, :boolean, default: false, null: false
    execute "UPDATE users SET has_seen_welcome = TRUE WHERE welcome_seen_at IS NOT NULL"
    remove_column :users, :welcome_seen_at
  end
end
