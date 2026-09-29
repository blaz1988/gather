require "rails_helper"

RSpec.describe User do
  it "needs a name and a unique email address" do
    create(:user, email_address: "ana@gather.test")
    expect(build(:user, name: "")).not_to be_valid
    expect(build(:user, email_address: " ANA@gather.test ")).not_to be_valid
  end

  describe "destroying" do
    let(:event) { create(:event, capacity: 1) }

    it "frees the seat of a going user and promotes the next person" do
      going = create(:rsvp, event:, created_at: 2.minutes.ago)
      waiting = create(:rsvp, :waitlisted, event:, created_at: 1.minute.ago)

      going.user.destroy!

      expect(waiting.reload).to be_going
      expect(event.rsvps.count).to eq(1)
    end

    it "removes the RSVPs of an organizer's events" do
      create(:rsvp, event:)
      create(:rsvp, :waitlisted, event:)
      create(:rsvp, user: event.organizer)

      expect { event.organizer.destroy! }.to change(Rsvp, :count).by(-3)
      expect(Event.exists?(event.id)).to be(false)
    end
  end
end
