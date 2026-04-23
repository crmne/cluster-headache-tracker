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

ActiveRecord::Schema[8.1].define(version: 2026_04_23_163510) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "feedback_surveys", force: :cascade do |t|
    t.text "additional_features"
    t.text "change_suggestion"
    t.datetime "created_at", null: false
    t.integer "ease_of_use"
    t.text "impact"
    t.string "mobile_interest"
    t.text "most_useful_features"
    t.text "promotion_suggestions"
    t.integer "recommendation_likelihood"
    t.boolean "shared_with_doctor"
    t.datetime "updated_at", null: false
    t.string "usage_duration"
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.text "versions"
    t.index ["user_id"], name: "index_feedback_surveys_on_user_id"
  end

  create_table "headache_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "end_time"
    t.integer "intensity"
    t.string "medication"
    t.text "notes"
    t.datetime "start_time"
    t.text "triggers"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_headache_logs_on_user_id"
  end

  create_table "mobile_release_snapshots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "fetched_at"
    t.string "latest_version"
    t.string "minimum_supported_version"
    t.string "platform", null: false
    t.string "release_notes_url"
    t.string "release_url"
    t.string "source"
    t.datetime "updated_at", null: false
    t.index ["platform"], name: "index_mobile_release_snapshots_on_platform", unique: true
  end

  create_table "share_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "token"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_share_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "has_seen_welcome", default: false, null: false
    t.string "last_seen_changelog"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "feedback_surveys", "users"
  add_foreign_key "headache_logs", "users"
  add_foreign_key "share_tokens", "users"
end
