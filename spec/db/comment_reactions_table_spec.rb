require "rails_helper"

RSpec.describe "comment_reactions table" do
  include CommentReactionsTableHelpers

  let(:event) { create(:event) }
  let(:user) { create(:user) }
  let(:comment) { create(:comment, event: event) }

  it "has NOT NULL comment_id, user_id, kind and timestamps, and no kind default" do
    columns = db.columns(:comment_reactions).index_by(&:name)

    expect(columns.keys).to contain_exactly("id", "comment_id", "user_id", "kind", "created_at", "updated_at")
    expect(columns.values_at("comment_id", "user_id", "kind", "created_at", "updated_at").map(&:null)).to all(be(false))
    expect(columns["comment_id"].type).to eq(:integer)
    expect(columns["user_id"].type).to eq(:integer)
    expect(columns["kind"].type).to eq(:string)
    expect(columns["kind"].default).to be_nil
  end

  it "rejects a row without a comment, user or kind" do
    now = "CURRENT_TIMESTAMP, CURRENT_TIMESTAMP"
    [
      "INSERT INTO comment_reactions (user_id, kind, created_at, updated_at) VALUES (#{user.id}, 'like', #{now})",
      "INSERT INTO comment_reactions (comment_id, kind, created_at, updated_at) VALUES (#{comment.id}, 'like', #{now})",
      "INSERT INTO comment_reactions (comment_id, user_id, created_at, updated_at) VALUES (#{comment.id}, #{user.id}, #{now})"
    ].each do |sql|
      expect { db.execute(sql) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  it "rejects rows pointing at a missing comment or user" do
    expect { insert_comment_reaction(comment_id: 0, user_id: user.id) }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect { insert_comment_reaction(comment_id: comment.id, user_id: 0) }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "accepts only 'like' and 'dislike' as kind" do
    constraint = db.check_constraints(:comment_reactions).find { |c| c.name == "comment_reactions_kind_check" }
    expect(constraint.expression).to eq("kind IN ('like', 'dislike')")

    expect { insert_comment_reaction(comment_id: comment.id, user_id: user.id, kind: "like") }.not_to raise_error
    expect { insert_comment_reaction(comment_id: comment.id, user_id: create(:user).id, kind: "dislike") }.not_to raise_error
    expect {
      insert_comment_reaction(comment_id: comment.id, user_id: create(:user).id, kind: "love")
    }.to raise_error(ActiveRecord::StatementInvalid, /CHECK constraint failed: comment_reactions_kind_check/)
  end

  it "allows one row per comment and user through a unique index" do
    index = comment_reactions_index("index_comment_reactions_on_comment_id_and_user_id")
    expect(index.columns).to eq(%w[ comment_id user_id ])
    expect(index.unique).to be(true)

    insert_comment_reaction(comment_id: comment.id, user_id: user.id, kind: "like")

    expect {
      insert_comment_reaction(comment_id: comment.id, user_id: user.id, kind: "dislike")
    }.to raise_error(ActiveRecord::RecordNotUnique, /comment_reactions\.comment_id, comment_reactions\.user_id/)
    expect { insert_comment_reaction(comment_id: comment.id, user_id: create(:user).id) }.not_to raise_error
  end

  it "indexes rows by user, and not by comment alone" do
    expect(comment_reactions_index("index_comment_reactions_on_user_id").columns).to eq(%w[ user_id ])
    expect(db.indexes(:comment_reactions).map(&:columns)).not_to include(%w[ comment_id ])
  end

  it "cascades deletes of comments and users" do
    expect(db.foreign_keys(:comment_reactions).map { |fk| [ fk.to_table, fk.column, fk.on_delete ] })
      .to contain_exactly([ "comments", "comment_id", :cascade ], [ "users", "user_id", :cascade ])
  end

  it "deletes a comment's reactions when the comment is deleted in SQL" do
    other = create(:comment, event: event)
    insert_comment_reaction(comment_id: comment.id, user_id: user.id)
    insert_comment_reaction(comment_id: other.id, user_id: user.id)

    db.execute("DELETE FROM comments WHERE id = #{comment.id}")

    expect(comment_reactions_count("comment_id = #{comment.id}")).to eq(0)
    expect(comment_reactions_count("comment_id = #{other.id}")).to eq(1)
  end

  it "lets an event whose comments have reactions be destroyed" do
    insert_comment_reaction(comment_id: comment.id, user_id: user.id)
    insert_comment_reaction(comment_id: comment.id, user_id: event.organizer.id, kind: "dislike")

    expect { event.destroy! }.not_to raise_error

    expect(comment_reactions_count).to eq(0)
  end

  it "deletes a destroyed user's reactions and the reactions on their comments" do
    author = comment.user
    others_comment = create(:comment, event: event)
    insert_comment_reaction(comment_id: others_comment.id, user_id: author.id)
    insert_comment_reaction(comment_id: comment.id, user_id: user.id, kind: "dislike")
    insert_comment_reaction(comment_id: others_comment.id, user_id: user.id)

    expect { author.destroy! }.not_to raise_error

    expect(comment_reactions_count("user_id = #{author.id}")).to eq(0)
    expect(comment_reactions_count("comment_id = #{comment.id}")).to eq(0)
    expect(comment_reactions_count).to eq(1)
  end

  it "rolls back by dropping only the comment_reactions table" do
    create(:rsvp, event: event, user: user)
    Session.create!(user: user)
    insert_comment_reaction(comment_id: comment.id, user_id: user.id)
    before = table_snapshot(:comments, :events, :users, :rsvps, :sessions)

    run_create_comment_reactions(:down)

    expect(db.table_exists?(:comment_reactions)).to be(false)
    expect(table_snapshot(:comments, :events, :users, :rsvps, :sessions)).to eq(before)
  ensure
    run_create_comment_reactions(:up) unless db.table_exists?(:comment_reactions)
  end
end
