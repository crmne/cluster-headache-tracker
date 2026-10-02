class CreateMedicationDoses < ActiveRecord::Migration[8.1]
  def change
    create_table :medication_doses do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :medication, null: false, foreign_key: true, index: false
      t.references :headache_log, foreign_key: true
      t.datetime :taken_at, null: false
      t.decimal :amount, precision: 8, scale: 2
      t.string :unit
      t.integer :duration_minutes
      t.string :effectiveness
      t.integer :minutes_to_relief

      t.timestamps
    end

    add_index :medication_doses, %i[ user_id taken_at ]
    add_index :medication_doses, %i[ medication_id taken_at ]

    add_check_constraint :medication_doses, "amount >= 0", name: "medication_doses_amount_non_negative"
    add_check_constraint :medication_doses, "duration_minutes > 0", name: "medication_doses_duration_positive"
    add_check_constraint :medication_doses, "minutes_to_relief >= 0", name: "medication_doses_minutes_to_relief_non_negative"
  end
end
