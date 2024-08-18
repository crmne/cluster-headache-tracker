class AddUsernameToUsers < ActiveRecord::Migration[7.2]
  def up
    # Add username column
    add_column :users, :username, :string

    # Copy email to username
    User.reset_column_information
    User.find_each do |user|
      user.update_column(:username, user.email)
    end

    # Make username not nullable and add index
    change_column_null :users, :username, false
    add_index :users, :username, unique: true

    # Remove email column and index
    remove_index :users, :email
    remove_column :users, :email, :string
  end

  def down
    # Add email column back
    add_column :users, :email, :string

    # Copy username back to email
    User.reset_column_information
    User.find_each do |user|
      user.update_column(:email, user.username)
    end

    # Make email not nullable and add index
    change_column_null :users, :email, false
    add_index :users, :email, unique: true

    # Remove username column and index
    remove_index :users, :username
    remove_column :users, :username, :string
  end
end
