class AddConstraintsToHeadacheLogs < ActiveRecord::Migration[8.1]
  def change
    reversible do |dir|
      dir.up do
        invalid_rows = select_value(<<~SQL).to_i
          SELECT COUNT(*) FROM headache_logs
          WHERE start_time IS NULL OR intensity IS NULL OR intensity NOT BETWEEN 1 AND 10
        SQL

        if invalid_rows.positive?
          raise "Cannot add constraints: #{invalid_rows} headache_logs rows have NULL or out-of-range values"
        end
      end
    end

    change_column_null :headache_logs, :start_time, false
    change_column_null :headache_logs, :intensity, false
    add_check_constraint :headache_logs, "intensity BETWEEN 1 AND 10", name: "headache_logs_intensity_range"
  end
end
