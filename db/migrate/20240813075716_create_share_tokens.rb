class CreateShareTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :share_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
