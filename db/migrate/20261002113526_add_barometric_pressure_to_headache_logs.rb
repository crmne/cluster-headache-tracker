class AddBarometricPressureToHeadacheLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :headache_logs, :barometric_pressure, :decimal, precision: 5, scale: 1
    add_check_constraint :headache_logs, "barometric_pressure BETWEEN 870 AND 1085", name: "headache_logs_barometric_pressure_range"
  end
end
