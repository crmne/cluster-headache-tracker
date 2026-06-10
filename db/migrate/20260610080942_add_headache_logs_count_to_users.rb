class AddHeadacheLogsCountToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :headache_logs_count, :integer, default: 0, null: false

    User.reset_column_information
    User.find_each { |user| User.reset_counters(user.id, :headache_logs) }
  end

  def down
    remove_column :users, :headache_logs_count
  end
end
