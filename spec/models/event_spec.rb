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

  it "deletes its comments when destroyed" do
    event = create(:event)
    create_list(:comment, 2, event:)
    other = create(:comment)

    expect { event.destroy! }.to change(Comment, :count).by(-2)
    expect(Comment.all).to eq([ other ])
  end

  describe "seats" do
    it "has every seat left and an empty waitlist before anyone RSVPs" do
      event = create(:event, capacity: 3)

      expect(event.seats_left).to eq(3)
      expect(event).not_to be_full
      expect(event.waitlist_count).to eq(0)
    end

    it "never has fewer than 0 seats left when capacity is below the going count" do
      event = create(:event, capacity: 2)
      create_list(:rsvp, 3, event:)

      expect(event.seats_taken).to eq(3)
      expect(event.seats_left).to eq(0)
      expect(event).to be_full
    end

    it "computes seats left from a preloaded going count without querying rsvps" do
      event = create(:event, capacity: 3)

      queries = []
      ActiveSupport::Notifications.subscribed(->(*, payload) { queries << payload[:sql] }, "sql.active_record") do
        expect(event.seats_left(1)).to eq(2)
        expect(event.seats_left(5)).to eq(0)
      end
      expect(queries).to be_empty
    end

    it "counts seats taken once per instance" do
      event = create(:event)
      create(:rsvp, event:)

      expect(event.seats_taken).to eq(1)
      create(:rsvp, event:)
      expect(event.seats_taken).to eq(1)
      expect(event.reload.seats_taken).to eq(2)
    end

    it "lists going users as attendees" do
      event = create(:event)
      going = create(:rsvp, event:)
      create(:rsvp, :waitlisted, event:)

      expect(event.attendees).to eq([ going.user ])
    end
  end

  describe "#rsvp_for" do
    it "finds the person's RSVP and is nil for a guest" do
      rsvp = create(:rsvp)

      expect(rsvp.event.rsvp_for(rsvp.user)).to eq(rsvp)
      expect(rsvp.event.rsvp_for(create(:user))).to be_nil
      expect(rsvp.event.rsvp_for(nil)).to be_nil
    end
  end

  describe "#rsvp" do
    let(:event) { create(:event, capacity: 2) }

    it "gives going seats until capacity, then waitlist places" do
      rsvps = create_list(:user, 4).map { event.rsvp(it) }

      expect(rsvps.map(&:status)).to eq(%w[ going going waitlisted waitlisted ])
      expect(rsvps.map(&:waitlist_position)).to eq([ nil, nil, 1, 2 ])
      expect(event.seats_left).to eq(0)
      expect(event.waitlist_count).to eq(2)
    end

    it "returns the same record when called twice" do
      create(:rsvp, event:)
      going = create(:user)
      waiting_for = create(:user)
      first = event.rsvp(going)
      waiting = event.rsvp(waiting_for)

      expect {
        expect(event.rsvp(going)).to eq(first)
        expect(event.rsvp(waiting_for)).to eq(waiting)
      }.not_to change { [ event.rsvps.going.count, event.rsvps.waitlisted.count ] }
    end

    it "returns the existing row when a racing insert wins" do
      user = create(:user)
      existing = create(:rsvp, event:, user:)
      allow(event.rsvps).to receive(:find_by).with(user:).and_return(nil, existing)
      allow(event.rsvps).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)

      expect(event.rsvp(user)).to eq(existing)
    end

    it "does not RSVP the organizer" do
      expect { expect(event.rsvp(event.organizer)).to be_nil }.not_to change(Rsvp, :count)
    end

    it "does not RSVP once the event has started" do
      event.update!(starts_at: 1.minute.ago)

      expect(event).not_to be_rsvps_open
      expect { expect(event.rsvp(create(:user))).to be_nil }.not_to change(Rsvp, :count)
    end

    it "does not RSVP a guest" do
      expect(event.rsvp(nil)).to be_nil
    end

    context "when several people race for the last seat" do
      self.use_transactional_tests = false

      after { [ Rsvp, Session, Event, User ].each(&:delete_all) }

      it "seats exactly one of them" do
        event = create(:event, capacity: 2)
        create(:rsvp, event:)
        racers = create_list(:user, 4)
        start = Concurrent::CountDownLatch.new(1)

        threads = racers.map do |user|
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              start.wait
              Event.find(event.id).rsvp(user)
            end
          end
        end
        start.count_down
        threads.each(&:join)

        statuses = Rsvp.where(user: racers).pluck(:status)
        expect(statuses.tally).to eq("going" => 1, "waitlisted" => 3)
        expect(event.rsvps.going.count).to eq(event.capacity)
      end
    end
  end
end
