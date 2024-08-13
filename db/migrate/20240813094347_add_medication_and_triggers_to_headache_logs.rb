class AddMedicationAndTriggersToHeadacheLogs < ActiveRecord::Migration[7.2]
  def change
    add_column :headache_logs, :medication, :string
    add_column :headache_logs, :triggers, :text
  end
end
