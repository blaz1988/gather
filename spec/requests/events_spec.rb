require "rails_helper"

RSpec.describe "Events", type: :request do
  let(:organizer) { create(:user, name: "Ana Kovač") }
  let!(:event) { create(:event, title: "Ruby Zagreb Meetup", organizer: organizer) }

  it "lists upcoming events for everyone" do
    get events_path
    expect(response.body).to include("Ruby Zagreb Meetup", "Organized by Ana Kovač")
  end

  it "shows an event to guests" do
    get event_path(event)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Edit event")
  end

  describe "RSVP card" do
    let(:event) { create(:event, organizer: organizer, capacity: 1) }
    let(:marko) { create(:user, name: "Marko Horvat") }

    it "shows seats left and a sign-in link to guests" do
      get event_path(event)
      expect(response.body).to include("Seats left: 1 of 1", "Sign in to RSVP")
      expect(response.body).not_to include(">RSVP<")
    end

    it "offers an RSVP button to a signed-in person" do
      sign_in marko
      get event_path(event)
      expect(response.body).to include(">RSVP<", event_rsvp_path(event))
    end

    it "shows the going status with a cancel button" do
      event.rsvp(marko)
      sign_in marko
      get event_path(event)
      expect(response.body).to include("You're going", "Cancel RSVP", "Full · 0 waiting")
    end

    it "offers the waitlist when full and shows the waitlist position" do
      event.rsvp(create(:user))
      sign_in marko
      get event_path(event)
      expect(response.body).to include("Join waitlist")

      event.rsvp(marko)
      get event_path(event)
      expect(response.body).to include("You're #1 on the waitlist", "Leave waitlist", "Full · 1 waiting")
    end

    it "shows no RSVP buttons to the organizer" do
      sign_in organizer
      get event_path(event)
      expect(response.body).not_to include(event_rsvp_path(event))
    end

    it "shows no RSVP buttons once the event has started" do
      event.rsvp(marko)
      event.update!(starts_at: 1.hour.ago)
      sign_in marko
      get event_path(event)
      expect(response.body).not_to include(event_rsvp_path(event), "Sign in to RSVP")
    end
  end

  it "asks guests to sign in before creating an event" do
    get new_event_path
    expect(response).to redirect_to(new_session_path)
  end

  it "creates an event organized by the signed-in person" do
    sign_in organizer
    post events_path, params: { event: { title: "Hotwire night", venue: "Impact Hub", capacity: 10,
                                         starts_at: 3.days.from_now } }

    created = Event.find_by!(title: "Hotwire night")
    expect(created.organizer).to eq(organizer)
    expect(response).to redirect_to(event_path(created))
  end

  it "lets only the organizer edit" do
    sign_in create(:user)
    patch event_path(event), params: { event: { title: "Taken over" } }
    expect(event.reload.title).to eq("Ruby Zagreb Meetup")

    sign_in organizer
    patch event_path(event), params: { event: { title: "Ruby Zagreb Meetup #43" } }
    expect(event.reload.title).to eq("Ruby Zagreb Meetup #43")
  end
end
