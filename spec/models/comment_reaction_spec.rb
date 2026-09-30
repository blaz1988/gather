require "rails_helper"

RSpec.describe CommentReaction do
  it "needs a comment, a user and a known kind" do
    expect(build(:comment_reaction)).to be_valid
    expect(build(:comment_reaction, :dislike)).to be_valid
    expect(build(:comment_reaction, comment: nil)).not_to be_valid
    expect(build(:comment_reaction, user: nil)).not_to be_valid
    expect(build(:comment_reaction, kind: nil)).not_to be_valid
    expect(build(:comment_reaction, kind: "love")).not_to be_valid
  end

  it "allows one reaction per person per comment" do
    first = create(:comment_reaction)
    duplicate = build(:comment_reaction, :dislike, comment: first.comment, user: first.user)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors.full_messages).to eq([ "User has already been taken" ])
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "lets the same person react to a different comment" do
    first = create(:comment_reaction)
    expect(build(:comment_reaction, user: first.user)).to be_valid
  end

  it "is removed with its comment and with its user" do
    reaction = create(:comment_reaction)
    reaction.comment.destroy!
    expect(described_class.exists?(reaction.id)).to be(false)

    reaction = create(:comment_reaction)
    reaction.user.destroy!
    expect(described_class.exists?(reaction.id)).to be(false)
  end
end
