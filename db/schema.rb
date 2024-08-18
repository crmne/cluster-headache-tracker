# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_08_18_175417) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "headache_logs", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "intensity"
    t.text "notes"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "medication"
    t.text "triggers"
    t.index ["user_id"], name: "index_headache_logs_on_user_id"
  end

  create_table "medication_types", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_medication_types_on_user_id"
  end

  create_table "medications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "dosage"
    t.datetime "taken_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "medication_type_id", null: false
    t.index ["medication_type_id"], name: "index_medications_on_medication_type_id"
    t.index ["user_id"], name: "index_medications_on_user_id"
  end

  create_table "share_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_share_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "headache_logs", "users"
  add_foreign_key "medication_types", "users"
  add_foreign_key "medications", "medication_types"
  add_foreign_key "medications", "users"
  add_foreign_key "share_tokens", "users"
end
