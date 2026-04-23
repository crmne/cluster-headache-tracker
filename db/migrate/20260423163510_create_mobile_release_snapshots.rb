class CreateMobileReleaseSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :mobile_release_snapshots do |t|
      t.string :platform, null: false
      t.string :latest_version
      t.string :minimum_supported_version
      t.string :release_url
      t.string :release_notes_url
      t.string :source
      t.datetime :fetched_at

      t.timestamps
    end

    add_index :mobile_release_snapshots, :platform, unique: true
  end
end
