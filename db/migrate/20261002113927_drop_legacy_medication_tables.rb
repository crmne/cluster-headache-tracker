# Production still has empty medications and medication_types tables from an
# abandoned medication experiment that never made it into schema.rb. They block
# CreateMedications, so drop them first, but only while they're the legacy
# shape and empty: a database that already has the new medications table, or
# legacy rows, is left alone.
class DropLegacyMedicationTables < ActiveRecord::Migration[8.1]
  def up
    if legacy_medications_table?
      drop_empty_table :medications
      drop_empty_table :medication_types if table_exists?(:medication_types)
    end
  end

  def down
  end

  private
    def legacy_medications_table?
      table_exists?(:medications) && column_exists?(:medications, :dosage)
    end

    def drop_empty_table(table)
      if select_value("SELECT EXISTS (SELECT 1 FROM #{quote_table_name(table)})")
        raise "Refusing to drop the legacy #{table} table: it has rows"
      else
        drop_table table
      end
    end
end
