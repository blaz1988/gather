require "rails_helper"

RSpec.describe "rsvps table" do
  include RsvpsTableHelpers

  let(:event) { create(:event) }
  let(:user) { create(:user) }

  it "has NOT NULL event_id, user_id, status and timestamps, and no status default" do
    columns = db.columns(:rsvps).index_by(&:name)

    expect(columns.keys).to contain_exactly("id", "event_id", "user_id", "status", "created_at", "updated_at")
    expect(columns.values_at("event_id", "user_id", "status", "created_at", "updated_at").map(&:null)).to all(be(false))
    expect(columns["event_id"].type).to eq(:integer)
    expect(columns["user_id"].type).to eq(:integer)
    expect(columns["status"].type).to eq(:string)
    expect(columns["status"].default).to be_nil
  end

  it "rejects a row without a status" do
    expect {
      db.execute("INSERT INTO rsvps (event_id, user_id, created_at, updated_at) VALUES (#{event.id}, #{user.id}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
    }.to raise_error(ActiveRecord::NotNullViolation)
  end

  it "allows one row per event and user through a unique index" do
    index = rsvps_index("index_rsvps_on_event_id_and_user_id")
    expect(index.columns).to eq(%w[ event_id user_id ])
    expect(index.unique).to be(true)

    insert_rsvp(event_id: event.id, user_id: user.id, status: "going")

    expect {
      insert_rsvp(event_id: event.id, user_id: user.id, status: "waitlisted")
    }.to raise_error(ActiveRecord::RecordNotUnique, /rsvps\.event_id, rsvps\.user_id/)
    expect { insert_rsvp(event_id: event.id, user_id: create(:user).id) }.not_to raise_error
  end

  it "accepts only 'going' and 'waitlisted' as status" do
    constraint = db.check_constraints(:rsvps).find { |c| c.name == "rsvps_status_check" }
    expect(constraint.expression).to eq("status IN ('going', 'waitlisted')")

    expect { insert_rsvp(event_id: event.id, user_id: user.id, status: "going") }.not_to raise_error
    expect { insert_rsvp(event_id: event.id, user_id: create(:user).id, status: "waitlisted") }.not_to raise_error
    expect {
      insert_rsvp(event_id: event.id, user_id: create(:user).id, status: "maybe")
    }.to raise_error(ActiveRecord::StatementInvalid, /CHECK constraint failed: rsvps_status_check/)
  end

  it "indexes seat lookups by event, status and created_at, and rows by user" do
    expect(rsvps_index("index_rsvps_on_event_id_and_status_and_created_at").columns).to eq(%w[ event_id status created_at ])
    expect(rsvps_index("index_rsvps_on_user_id").columns).to eq(%w[ user_id ])
    expect(db.indexes(:rsvps).map(&:name)).not_to include("index_rsvps_on_event_id")
  end

  it "rejects rows pointing at a missing event or user" do
    expect { insert_rsvp(event_id: 0, user_id: user.id) }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect { insert_rsvp(event_id: event.id, user_id: 0) }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "does not cascade deletes of events or users" do
    expect(db.foreign_keys(:rsvps).map { |fk| [ fk.to_table, fk.column, fk.on_delete ] })
      .to contain_exactly([ "events", "event_id", nil ], [ "users", "user_id", nil ])

    insert_rsvp(event_id: event.id, user_id: user.id)

    expect { db.execute("DELETE FROM events WHERE id = #{event.id}") }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect { db.execute("DELETE FROM users WHERE id = #{user.id}") }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect(db.select_value("SELECT COUNT(*) FROM rsvps")).to eq(1)
  end

  it "rolls back by dropping only the rsvps table" do
    Session.create!(user: event.organizer)
    before = table_snapshot(:events, :users, :sessions)

    run_create_rsvps(:down)

    expect(db.table_exists?(:rsvps)).to be(false)
    expect(table_snapshot(:events, :users, :sessions)).to eq(before)
  ensure
    run_create_rsvps(:up) unless db.table_exists?(:rsvps)
  end
end
