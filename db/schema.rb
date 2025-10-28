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

ActiveRecord::Schema[8.0].define(version: 2025_10_28_020120) do
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
    t.index [ "leetcode_id" ], name: "index_leet_code_problems_on_leetcode_id", unique: true
  end

  create_table "leet_code_session_problems", force: :cascade do |t|
    t.bigint "leet_code_session_id", null: false
    t.bigint "leet_code_problem_id", null: false
    t.boolean "solved", default: false
    t.datetime "solved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "leet_code_problem_id" ], name: "index_leet_code_session_problems_on_leet_code_problem_id"
    t.index [ "leet_code_session_id" ], name: "index_leet_code_session_problems_on_leet_code_session_id"
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
    t.index [ "user_id" ], name: "index_leet_code_sessions_on_user_id"
  end

  create_table "lobbies", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.text "description"
    t.string "lobby_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index [ "lobby_code" ], name: "index_lobbies_on_lobby_code", unique: true
    t.index [ "owner_id" ], name: "index_lobbies_on_owner_id"
  end

  create_table "lobby_members", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lobby_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "can_draw", default: false
    t.boolean "can_edit_notes", default: false
    t.boolean "can_speak", default: false
    t.index [ "lobby_id" ], name: "index_lobby_members_on_lobby_id"
    t.index [ "user_id" ], name: "index_lobby_members_on_user_id"
  end

  create_table "lobby_participations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lobby_id", null: false
    t.boolean "can_draw", default: false
    t.boolean "can_edit_notes", default: false
    t.boolean "can_speak", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "lobby_id" ], name: "index_lobby_participations_on_lobby_id"
    t.index [ "user_id", "lobby_id" ], name: "index_lobby_participations_on_user_id_and_lobby_id", unique: true
    t.index [ "user_id" ], name: "index_lobby_participations_on_user_id"
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
    t.index [ "active" ], name: "index_users_on_active"
    t.index [ "email" ], name: "index_users_on_email", unique: true
    t.index [ "netid" ], name: "index_users_on_netid", unique: true
  end

  add_foreign_key "leet_code_session_problems", "leet_code_problems"
  add_foreign_key "leet_code_session_problems", "leet_code_sessions"
  add_foreign_key "leet_code_sessions", "users"
  add_foreign_key "lobbies", "users", column: "owner_id"
  add_foreign_key "lobby_members", "lobbies"
  add_foreign_key "lobby_members", "users"
  add_foreign_key "lobby_participations", "lobbies"
  add_foreign_key "lobby_participations", "users"
end
