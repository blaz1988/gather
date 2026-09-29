require "rails_helper"

RSpec.describe Event do
  it "needs a positive whole capacity" do
    expect(build(:event, capacity: 0)).not_to be_valid
    expect(build(:event, capacity: 2.5)).not_to be_valid
    expect(build(:event, capacity: 1)).to be_valid
  end

  it "lists upcoming events soonest first" do
    later = create(:event, starts_at: 2.weeks.from_now)
    sooner = create(:event, starts_at: 1.day.from_now)
    create(:event, starts_at: 1.day.ago)

    expect(Event.upcoming).to eq([ sooner, later ])
  end

  it "knows its organizer" do
    event = create(:event)
    expect(event.organized_by?(event.organizer)).to be(true)
    expect(event.organized_by?(create(:user))).to be(false)
    expect(event.organized_by?(nil)).to be(false)
  end
end
