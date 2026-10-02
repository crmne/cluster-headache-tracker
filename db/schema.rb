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

ActiveRecord::Schema[8.1].define(version: 2026_10_02_114511) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.index ["user_id"], name: "index_feedback_surveys_on_user_id", unique: true
  end

  create_table "headache_logs", force: :cascade do |t|
    t.decimal "barometric_pressure", precision: 5, scale: 1
    t.datetime "created_at", null: false
    t.datetime "end_time"
    t.integer "intensity", null: false
    t.string "medication"
    t.text "notes"
    t.datetime "start_time", null: false
    t.text "triggers"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_headache_logs_on_user_id"
    t.check_constraint "barometric_pressure >= 870::numeric AND barometric_pressure <= 1085::numeric", name: "headache_logs_barometric_pressure_range"
    t.check_constraint "intensity >= 1 AND intensity <= 10", name: "headache_logs_intensity_range"
  end

  create_table "medication_doses", force: :cascade do |t|
    t.decimal "amount", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.integer "duration_minutes"
    t.string "effectiveness"
    t.bigint "headache_log_id"
    t.bigint "medication_id", null: false
    t.integer "minutes_to_relief"
    t.datetime "taken_at", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["headache_log_id"], name: "index_medication_doses_on_headache_log_id"
    t.index ["medication_id", "taken_at"], name: "index_medication_doses_on_medication_id_and_taken_at"
    t.index ["user_id", "taken_at"], name: "index_medication_doses_on_user_id_and_taken_at"
    t.check_constraint "amount >= 0::numeric", name: "medication_doses_amount_non_negative"
    t.check_constraint "duration_minutes > 0", name: "medication_doses_duration_positive"
    t.check_constraint "minutes_to_relief >= 0", name: "medication_doses_minutes_to_relief_non_negative"
  end

  create_table "medications", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.decimal "default_dose", precision: 8, scale: 2
    t.string "frequency", default: "as_needed", null: false
    t.string "kind", default: "abortive", null: false
    t.string "name", null: false
    t.string "schedule_note"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index "user_id, lower((name)::text)", name: "index_medications_on_user_id_and_lower_name", unique: true
    t.check_constraint "default_dose >= 0::numeric", name: "medications_default_dose_non_negative"
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
    t.datetime "expires_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["token"], name: "index_share_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_share_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "headache_logs_count", default: 0, null: false
    t.string "last_seen_changelog"
    t.string "locale"
    t.datetime "remember_created_at"
    t.datetime "review_prompted_at"
    t.string "time_format"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.datetime "welcome_seen_at"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "feedback_surveys", "users"
  add_foreign_key "headache_logs", "users"
  add_foreign_key "medication_doses", "headache_logs"
  add_foreign_key "medication_doses", "medications"
  add_foreign_key "medication_doses", "users"
  add_foreign_key "medications", "users"
  add_foreign_key "share_tokens", "users"
end
