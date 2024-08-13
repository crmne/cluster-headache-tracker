class CreateHeadacheLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :headache_logs do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.integer :intensity
      t.text :notes
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
