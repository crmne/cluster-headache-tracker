class CreateMedications < ActiveRecord::Migration[8.1]
  def change
    create_table :medications do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :kind, null: false, default: "abortive"
      t.decimal :default_dose, precision: 8, scale: 2
      t.string :unit
      t.string :frequency, null: false, default: "as_needed"
      t.string :schedule_note
      t.string :color, null: false
      t.datetime :archived_at

      t.timestamps
    end

    add_index :medications, "user_id, lower(name)", unique: true, name: "index_medications_on_user_id_and_lower_name"
    add_check_constraint :medications, "default_dose >= 0", name: "medications_default_dose_non_negative"
  end
end
