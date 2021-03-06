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

ActiveRecord::Schema.define(version: 20200506205500) do

  create_table "applies", force: :cascade do |t|
    t.date "month"
    t.integer "mark", default: 0
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "authorizer"
    t.integer "apply_count", default: 0
    t.index ["user_id"], name: "index_applies_on_user_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.date "worked_on"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "note"
    t.string "overtime_instruction"
    t.string "instructor"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "applying_started_at"
    t.datetime "applying_finished_at"
    t.datetime "previous_started_at"
    t.datetime "previous_finished_at"
    t.integer "mark", default: 0
    t.integer "overtime_authorizer_id"
    t.integer "change_authorizer_id"
    t.string "applying_note"
    t.integer "change_checked", default: 0
    t.integer "overtime_mark", default: 0
    t.datetime "overtime_finished_at"
    t.string "overtime_note"
    t.datetime "overtime_applying_finished_at"
    t.string "overtime_applying_note"
    t.boolean "attendance_changed", default: false
    t.date "approval_date"
    t.integer "change_tomorrow", default: 0
    t.integer "applying_change_authorizer_id"
    t.integer "overtime_change_checked", default: 0
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "offices", force: :cascade do |t|
    t.string "name"
    t.string "office_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "office_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "department"
    t.datetime "basic_time", default: "2020-05-06 23:00:00"
    t.datetime "work_time", default: "2020-05-06 22:30:00"
    t.boolean "superior", default: false
    t.string "affiliation"
    t.integer "employee_number"
    t.string "uid"
    t.datetime "basic_work_time"
    t.datetime "designated_work_start_time"
    t.datetime "designated_work_end_time"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
