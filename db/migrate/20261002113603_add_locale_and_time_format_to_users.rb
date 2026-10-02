class AddLocaleAndTimeFormatToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :locale, :string
    add_column :users, :time_format, :string
  end
end
