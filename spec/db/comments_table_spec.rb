require "rails_helper"

RSpec.describe "comments table" do
  include CommentsTableHelpers

  let(:event) { create(:event) }
  let(:user) { create(:user) }

  it "has NOT NULL event_id, user_id, body and timestamps, and no body default" do
    columns = db.columns(:comments).index_by(&:name)

    expect(columns.keys).to contain_exactly("id", "event_id", "user_id", "body", "created_at", "updated_at")
    expect(columns.values_at("event_id", "user_id", "body", "created_at", "updated_at").map(&:null)).to all(be(false))
    expect(columns["event_id"].type).to eq(:integer)
    expect(columns["user_id"].type).to eq(:integer)
    expect(columns["body"].type).to eq(:text)
    expect(columns["body"].default).to be_nil
  end

  it "rejects a row without a body" do
    expect {
      db.execute("INSERT INTO comments (event_id, user_id, created_at, updated_at) VALUES (#{event.id}, #{user.id}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)")
    }.to raise_error(ActiveRecord::NotNullViolation)
  end

  it "rejects rows pointing at a missing event or user" do
    expect { insert_comment(event_id: 0, user_id: user.id) }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect { insert_comment(event_id: event.id, user_id: 0) }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "rejects an empty or space-only body" do
    constraint = db.check_constraints(:comments).find { |c| c.name == "comments_body_length_check" }
    expect(constraint.expression).to eq("length(trim(body)) > 0 AND length(body) <= 1000")

    [ "", "   " ].each do |body|
      expect {
        insert_comment(event_id: event.id, user_id: user.id, body: body)
      }.to raise_error(ActiveRecord::StatementInvalid, /CHECK constraint failed: comments_body_length_check/)
    end
  end

  it "counts characters, not bytes, against the 1,000 limit" do
    expect {
      insert_comment(event_id: event.id, user_id: user.id, body: "a" * 1001)
    }.to raise_error(ActiveRecord::StatementInvalid, /CHECK constraint failed: comments_body_length_check/)

    body = ("Čćž é 🎉 " * 125).first(1000)
    expect(body.length).to eq(1000)
    expect(body.bytesize).to be > 1000

    expect { insert_comment(event_id: event.id, user_id: user.id, body: body) }.not_to raise_error
    expect(db.select_value("SELECT body FROM comments")).to eq(body)
  end

  it "indexes comments by event and created_at, and by user" do
    expect(comments_index("index_comments_on_event_id_and_created_at").columns).to eq(%w[ event_id created_at ])
    expect(comments_index("index_comments_on_user_id").columns).to eq(%w[ user_id ])
    expect(db.indexes(:comments).map(&:columns)).not_to include(%w[ event_id ])
  end

  it "does not cascade deletes of events or users" do
    expect(db.foreign_keys(:comments).map { |fk| [ fk.to_table, fk.column, fk.on_delete ] })
      .to contain_exactly([ "events", "event_id", nil ], [ "users", "user_id", nil ])

    insert_comment(event_id: event.id, user_id: user.id)

    expect { db.execute("DELETE FROM events WHERE id = #{event.id}") }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect { db.execute("DELETE FROM users WHERE id = #{user.id}") }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect(db.select_value("SELECT COUNT(*) FROM comments")).to eq(1)
  end

  it "rolls back by dropping only the comments table" do
    create(:rsvp, event: event, user: user)
    Session.create!(user: user)
    before = table_snapshot(:events, :users, :rsvps, :sessions)

    run_create_comments(:down)

    expect(db.table_exists?(:comments)).to be(false)
    expect(table_snapshot(:events, :users, :rsvps, :sessions)).to eq(before)
  ensure
    run_create_comments(:up) unless db.table_exists?(:comments)
  end
end
