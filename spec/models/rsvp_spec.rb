require "rails_helper"

RSpec.describe Rsvp do
  let(:event) { create(:event, capacity: 1) }

  it "needs an event, a user and a known status" do
    expect(build(:rsvp)).to be_valid
    expect(build(:rsvp, event: nil)).not_to be_valid
    expect(build(:rsvp, user: nil)).not_to be_valid
    expect(build(:rsvp, status: nil)).not_to be_valid
    expect(build(:rsvp, status: "maybe")).not_to be_valid
  end

  it "rejects an unknown status in the database too" do
    rsvp = create(:rsvp)
    expect { rsvp.update_column(:status, "maybe") }.to raise_error(ActiveRecord::StatementInvalid, /rsvps_status_check/)
  end

  it "allows one RSVP per person per event" do
    first = create(:rsvp, event:)
    duplicate = build(:rsvp, :waitlisted, event:, user: first.user)

    expect(duplicate).not_to be_valid
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "orders the line by created_at, then id" do
    tie = 1.hour.ago
    later = create(:rsvp, :waitlisted, event:, created_at: tie)
    earlier = create(:rsvp, :waitlisted, event:, created_at: 2.hours.ago)
    same_time = create(:rsvp, :waitlisted, event:, created_at: tie)

    expect(event.rsvps.in_line_order).to eq([ earlier, later, same_time ])
  end

  describe "#waitlist_position" do
    it "counts 1, 2, 3 in created_at order and is nil for going" do
      going = create(:rsvp, event:)
      third = create(:rsvp, :waitlisted, event:, created_at: 1.minute.ago)
      first = create(:rsvp, :waitlisted, event:, created_at: 3.minutes.ago)
      second = create(:rsvp, :waitlisted, event:, created_at: 2.minutes.ago)

      expect([ first, second, third ].map(&:waitlist_position)).to eq([ 1, 2, 3 ])
      expect(going.waitlist_position).to be_nil
    end

    it "only counts the same event's waitlist" do
      create(:rsvp, :waitlisted, created_at: 1.hour.ago)
      expect(create(:rsvp, :waitlisted, event:).waitlist_position).to eq(1)
    end
  end

  describe "cancelling" do
    let!(:going) { create(:rsvp, event:, created_at: 3.minutes.ago) }
    let!(:first_waiting) { create(:rsvp, :waitlisted, event:, created_at: 2.minutes.ago) }
    let!(:second_waiting) { create(:rsvp, :waitlisted, event:, created_at: 1.minute.ago) }

    it "promotes only the oldest waitlisted RSVP when a going RSVP is destroyed" do
      going.destroy!

      expect(first_waiting.reload).to be_going
      expect(second_waiting.reload).to be_waitlisted
      expect(second_waiting.waitlist_position).to eq(1)
      expect(event.rsvps.going.count).to eq(1)
    end

    it "logs the promotion" do
      allow(Rails.logger).to receive(:info).and_call_original
      going.destroy!
      expect(Rails.logger).to have_received(:info)
        .with("Promoted RSVP from waitlist: event_id=#{event.id} user_id=#{first_waiting.user_id}")
    end

    it "promotes nobody and moves the line up when a waitlisted RSVP is destroyed" do
      first_waiting.destroy!

      expect(going.reload).to be_going
      expect(second_waiting.reload).to be_waitlisted
      expect(second_waiting.waitlist_position).to eq(1)
    end

    it "rolls the promotion back with the destroy" do
      Rsvp.transaction do
        going.destroy!
        raise ActiveRecord::Rollback
      end

      expect(going.reload).to be_going
      expect(first_waiting.reload).to be_waitlisted
    end
  end

  it "only frees a seat when nobody is waiting" do
    going = create(:rsvp, event:)

    expect { going.destroy! }.to change { event.rsvps.count }.from(1).to(0)
    expect(event.reload.seats_left).to eq(1)
  end
end
