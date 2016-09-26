# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160724230335) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "characters", force: :cascade do |t|
    t.string   "name",            null: false
    t.string   "normalized_name", null: false
    t.string   "gender"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "characters", ["name"], name: "index_characters_on_name", unique: true, using: :btree
  add_index "characters", ["normalized_name"], name: "index_characters_on_normalized_name", unique: true, using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "episodes", force: :cascade do |t|
    t.string   "title",                  null: false
    t.date     "original_air_date",      null: false
    t.string   "production_code",        null: false
    t.integer  "season",                 null: false
    t.integer  "number_in_season",       null: false
    t.integer  "number_in_series",       null: false
    t.float    "us_viewers_in_millions"
    t.integer  "views"
    t.float    "imdb_rating"
    t.integer  "imdb_votes"
    t.string   "image_url"
    t.string   "video_url"
    t.text     "full_html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "episodes", ["production_code"], name: "index_episodes_on_production_code", unique: true, using: :btree
  add_index "episodes", ["season", "number_in_season"], name: "index_episodes_on_season_and_number_in_season", unique: true, using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "name",            null: false
    t.string   "normalized_name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "locations", ["name"], name: "index_locations_on_name", unique: true, using: :btree
  add_index "locations", ["normalized_name"], name: "index_locations_on_normalized_name", unique: true, using: :btree

  create_table "script_lines", force: :cascade do |t|
    t.integer  "episode_id",         null: false
    t.integer  "number",             null: false
    t.text     "raw_text"
    t.integer  "timestamp_in_ms"
    t.boolean  "speaking_line",      null: false
    t.integer  "character_id"
    t.integer  "location_id"
    t.string   "raw_character_text"
    t.string   "raw_location_text"
    t.text     "spoken_words"
    t.text     "normalized_text"
    t.integer  "word_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "script_lines", ["episode_id", "number"], name: "index_script_lines_on_episode_id_and_number", unique: true, using: :btree

end
