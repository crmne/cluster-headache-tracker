class RemoveRecoverableColumnsFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_index :users, :reset_password_token, unique: true
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
  end
end
