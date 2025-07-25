class AddHasSeenWelcomeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :has_seen_welcome, :boolean, default: false, null: false
  end
end
