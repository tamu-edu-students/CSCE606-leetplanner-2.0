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

ActiveRecord::Schema[8.0].define(version: 2025_11_04_202500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "leet_code_problems", force: :cascade do |t|
    t.string "leetcode_id", null: false
    t.string "title"
    t.string "difficulty"
    t.string "url"
    t.text "tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "title_slug"
    t.text "description"
    t.index ["leetcode_id"], name: "index_leet_code_problems_on_leetcode_id", unique: true
  end

  create_table "leet_code_session_problems", force: :cascade do |t|
    t.bigint "leet_code_session_id", null: false
    t.bigint "leet_code_problem_id", null: false
    t.boolean "solved", default: false
    t.datetime "solved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["leet_code_problem_id"], name: "index_leet_code_session_problems_on_leet_code_problem_id"
    t.index ["leet_code_session_id"], name: "index_leet_code_session_problems_on_leet_code_session_id"
  end

  create_table "leet_code_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "scheduled_time"
    t.integer "duration_minutes"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_event_id"
    t.text "description"
    t.string "title"
    t.index ["user_id"], name: "index_leet_code_sessions_on_user_id"
  end

  create_table "lobbies", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.text "description"
    t.string "lobby_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.boolean "private", default: false
    t.index ["lobby_code"], name: "index_lobbies_on_lobby_code", unique: true
    t.index ["owner_id"], name: "index_lobbies_on_owner_id"
    t.index ["private"], name: "index_lobbies_on_private"
  end

  create_table "lobby_members", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lobby_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "can_draw", default: false
    t.boolean "can_edit_notes", default: false
    t.boolean "can_speak", default: false
    t.index ["lobby_id"], name: "index_lobby_members_on_lobby_id"
    t.index ["user_id"], name: "index_lobby_members_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lobby_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lobby_id"], name: "index_messages_on_lobby_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "content", default: ""
    t.bigint "lobby_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lobby_id"], name: "index_notes_on_lobby_id", unique: true
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "netid"
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_streak"
    t.integer "longest_streak"
    t.text "preferred_topics"
    t.boolean "active", default: true
    t.string "leetcode_username"
    t.string "google_access_token"
    t.string "google_refresh_token"
    t.datetime "google_token_expires_at"
    t.string "personal_email"
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["netid"], name: "index_users_on_netid", unique: true
  end

  create_table "whiteboards", force: :cascade do |t|
    t.bigint "lobby_id", null: false
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "svg_data"
    t.text "notes"
    t.index ["lobby_id"], name: "index_whiteboards_on_lobby_id"
  end

  add_foreign_key "leet_code_session_problems", "leet_code_problems"
  add_foreign_key "leet_code_session_problems", "leet_code_sessions"
  add_foreign_key "leet_code_sessions", "users"
  add_foreign_key "lobbies", "users", column: "owner_id"
  add_foreign_key "lobby_members", "lobbies"
  add_foreign_key "lobby_members", "users"
  add_foreign_key "messages", "lobbies"
  add_foreign_key "messages", "users"
  add_foreign_key "notes", "lobbies"
  add_foreign_key "notes", "users"
  add_foreign_key "whiteboards", "lobbies"
end
