class AddConstraintsToShareTokens < ActiveRecord::Migration[8.1]
  def change
    reversible do |dir|
      dir.up do
        execute "DELETE FROM share_tokens WHERE token IS NULL"
        execute "UPDATE share_tokens SET expires_at = created_at + INTERVAL '30 days' WHERE expires_at IS NULL"
      end
    end

    change_column_null :share_tokens, :token, false
    change_column_null :share_tokens, :expires_at, false
    add_index :share_tokens, :token, unique: true
  end
end
