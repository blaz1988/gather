require "rails_helper"

RSpec.describe "RSVPs", type: :request do
  let(:organizer) { create(:user, name: "Ana Kovač") }
  let(:event) { create(:event, organizer: organizer, capacity: 1) }
  let(:marko) { create(:user, name: "Marko Horvat") }
  let(:iva) { create(:user, name: "Iva Babić") }

  context "as a guest" do
    it "redirects POST to sign-in and creates nothing" do
      expect { post event_rsvp_path(event) }.not_to change(Rsvp, :count)
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects DELETE to sign-in and cancels nothing" do
      event.rsvp(marko)
      expect { delete event_rsvp_path(event) }.not_to change(Rsvp, :count)
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "when signed in" do
    before { sign_in marko }

    it "RSVPs the current person as going" do
      post event_rsvp_path(event)

      expect(event.rsvp_for(marko)).to be_going
      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to eq("You're going.")
    end

    it "puts the current person on the waitlist when the event is full" do
      event.rsvp(iva)
      post event_rsvp_path(event)

      expect(event.rsvp_for(marko)).to be_waitlisted
      expect(flash[:notice]).to eq("You're #1 on the waitlist.")
    end

    it "does nothing when the person has already RSVPed" do
      event.rsvp(marko)
      expect { post event_rsvp_path(event) }.not_to change(Rsvp, :count)
      expect(flash[:notice]).to eq("You're going.")
    end

    it "ignores user_id and status params" do
      event.rsvp(iva)
      post event_rsvp_path(event), params: { user_id: organizer.id, status: "going", rsvp: { user_id: organizer.id, status: "going" } }

      expect(event.rsvps.pluck(:user_id, :status)).to contain_exactly([ iva.id, "going" ], [ marko.id, "waitlisted" ])
    end

    it "does not RSVP to an event that has started" do
      event.update!(starts_at: 1.hour.ago)
      expect { post event_rsvp_path(event) }.not_to change(Rsvp, :count)
      expect(response).to redirect_to(event_path(event))
    end

    it "cancels only the current person's RSVP and promotes the next in line" do
      event.rsvp(marko)
      event.rsvp(iva)
      delete event_rsvp_path(event), params: { user_id: iva.id }

      expect(event.rsvp_for(marko)).to be_nil
      expect(event.rsvp_for(iva)).to be_going
      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to eq("Your RSVP was cancelled.")
    end

    it "redirects without error when there is no RSVP to cancel" do
      delete event_rsvp_path(event)
      expect(response).to redirect_to(event_path(event))
    end

    it "does not cancel once the event has started" do
      event.rsvp(marko)
      event.update!(starts_at: 1.hour.ago)

      expect { delete event_rsvp_path(event) }.not_to change(Rsvp, :count)
      expect(response).to redirect_to(event_path(event))
    end

    it "returns 404 for an unknown event" do
      post event_rsvp_path(event_id: 0)
      expect(response).to have_http_status(:not_found)

      delete event_rsvp_path(event_id: 0)
      expect(response).to have_http_status(:not_found)
    end
  end
end
