# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

seed_username = ENV["SEED_USER_USERNAME"]
seed_password = ENV["SEED_USER_PASSWORD"]

if seed_username.present? && seed_password.present?
  seed_user = User.find_or_initialize_by(username: seed_username)

  if seed_user.new_record? || !seed_user.valid_password?(seed_password)
    seed_user.password = seed_password
    seed_user.password_confirmation = seed_password
  end

  if seed_user.changed?
    seed_user.save!
    puts %(Seeded user "#{seed_user.username}")
  else
    puts %(Seed user "#{seed_user.username}" is already up to date)
  end
else
  puts "Skipping seed user. Set SEED_USER_USERNAME and SEED_USER_PASSWORD to enable it."
end
