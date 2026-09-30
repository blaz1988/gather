require "rails_helper"

RSpec.describe Comment do
  it "needs an event, a user and a body" do
    expect(build(:comment)).to be_valid
    expect(build(:comment, event: nil)).not_to be_valid
    expect(build(:comment, user: nil)).not_to be_valid
  end

  it "strips the body and rejects a blank or whitespace-only one" do
    [ nil, "", "   ", "\n\t \r\n" ].each do |body|
      expect(build(:comment, body:)).not_to be_valid, "expected #{body.inspect} to be invalid"
    end
    expect(build(:comment, body: "  \n Is there parking? \t").body).to eq("Is there parking?")
  end

  it "allows at most Comment::MAX_LENGTH characters" do
    expect(Comment::MAX_LENGTH).to eq(1_000)
    expect(build(:comment, body: "a" * 1_000)).to be_valid

    too_long = build(:comment, body: "a" * 1_001)
    expect(too_long).not_to be_valid
    expect(too_long.errors.full_messages).to eq([ "Body is too long (maximum is 1000 characters)" ])
  end

  it "lists an event's comments oldest first, then by id" do
    event = create(:event)
    tie = 1.hour.ago
    later = create(:comment, event:, created_at: tie)
    earlier = create(:comment, event:, created_at: 2.hours.ago)
    same_time = create(:comment, event:, created_at: tie)
    create(:comment, created_at: 3.hours.ago)

    expect(event.comments.oldest_first).to eq([ earlier, later, same_time ])
  end

  describe "#deletable_by?" do
    let(:comment) { create(:comment) }

    it "is true for the author" do
      expect(comment.deletable_by?(comment.user)).to be(true)
    end

    it "is false for another user" do
      expect(comment.deletable_by?(create(:user))).to be(false)
    end

    it "is false for nil" do
      expect(comment.deletable_by?(nil)).to be(false)
    end
  end
end
