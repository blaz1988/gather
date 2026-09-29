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

ActiveRecord::Schema[8.1].define(version: 2026_09_29_214624) do
  create_table "events", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.datetime "starts_at", null: false
    t.string "venue", null: false
    t.integer "capacity", null: false
    t.integer "organizer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organizer_id"], name: "index_events_on_organizer_id"
    t.index ["starts_at"], name: "index_events_on_starts_at"
  end

  create_table "plan_driven_approvals", force: :cascade do |t|
    t.string "approvable_type", null: false
    t.integer "approvable_id", null: false
    t.string "role", null: false
    t.string "decision", null: false
    t.string "actor", null: false
    t.integer "revision"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approvable_type", "approvable_id"], name: "index_plan_driven_approvals_on_approvable"
  end

  create_table "plan_driven_events", force: :cascade do |t|
    t.integer "plan_id", null: false
    t.integer "ticket_id"
    t.string "name", null: false
    t.string "actor", null: false
    t.json "payload"
    t.datetime "created_at", null: false
    t.index ["plan_id"], name: "index_plan_driven_events_on_plan_id"
    t.index ["ticket_id"], name: "index_plan_driven_events_on_ticket_id"
  end

  create_table "plan_driven_evidence_runs", force: :cascade do |t|
    t.integer "plan_id", null: false
    t.string "kind", null: false
    t.string "command"
    t.string "status", null: false
    t.string "commit_sha"
    t.json "results"
    t.datetime "created_at", null: false
    t.index ["plan_id"], name: "index_plan_driven_evidence_runs_on_plan_id"
  end

  create_table "plan_driven_plans", force: :cascade do |t|
    t.string "key", null: false
    t.string "title", null: false
    t.string "status", default: "draft", null: false
    t.integer "revision", default: 1, null: false
    t.json "interview"
    t.json "sections"
    t.json "guard_report"
    t.string "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_plan_driven_plans_on_key", unique: true
  end

  create_table "plan_driven_tickets", force: :cascade do |t|
    t.integer "plan_id", null: false
    t.string "key", null: false
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.string "kind", default: "code", null: false
    t.string "ticket_type", default: "TASK", null: false
    t.text "story"
    t.text "description"
    t.json "acceptance_criteria"
    t.text "implementation_notes"
    t.integer "estimate"
    t.json "depends_on"
    t.json "touches"
    t.string "status", default: "draft", null: false
    t.integer "issue_number"
    t.string "agent_id"
    t.string "agent_run_id"
    t.string "agent_url"
    t.string "branch"
    t.string "pr_url"
    t.integer "pr_number"
    t.string "merged_sha"
    t.json "guard_report"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id", "key"], name: "index_plan_driven_tickets_on_plan_id_and_key", unique: true
    t.index ["plan_id"], name: "index_plan_driven_tickets_on_plan_id"
  end

  create_table "rsvps", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "user_id", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "status", "created_at"], name: "index_rsvps_on_event_id_and_status_and_created_at"
    t.index ["event_id", "user_id"], name: "index_rsvps_on_event_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_rsvps_on_user_id"
    t.check_constraint "status IN ('going', 'waitlisted')", name: "rsvps_status_check"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "events", "users", column: "organizer_id"
  add_foreign_key "plan_driven_events", "plan_driven_plans", column: "plan_id"
  add_foreign_key "plan_driven_events", "plan_driven_tickets", column: "ticket_id"
  add_foreign_key "plan_driven_evidence_runs", "plan_driven_plans", column: "plan_id"
  add_foreign_key "plan_driven_tickets", "plan_driven_plans", column: "plan_id"
  add_foreign_key "rsvps", "events"
  add_foreign_key "rsvps", "users"
  add_foreign_key "sessions", "users"
end
