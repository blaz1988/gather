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
