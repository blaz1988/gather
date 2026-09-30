require "rails_helper"

RSpec.describe "Events", type: :request do
  let(:organizer) { create(:user, name: "Ana Kovač") }
  let!(:event) { create(:event, title: "Ruby Zagreb Meetup", organizer: organizer) }

  it "lists upcoming events for everyone" do
    get events_path
    expect(response.body).to include("Ruby Zagreb Meetup", "Organized by Ana Kovač")
  end

  describe "seats left on the index" do
    let!(:event) { create(:event, title: "Ruby Zagreb Meetup", organizer: organizer, capacity: 3) }

    def seats_label
      get events_path
      Nokogiri::HTML(response.body).at_css("##{ActionView::RecordIdentifier.dom_id(event)}").text.squish
    end

    it "shows every seat left when nobody has RSVPed" do
      expect(seats_label).to include("3 of 3 seats left")
    end

    it "counts going RSVPs as taken seats" do
      create(:rsvp, event: event)
      expect(seats_label).to include("2 of 3 seats left")
    end

    it "shows Full when every seat is taken" do
      create_list(:rsvp, 3, event: event)
      label = seats_label
      expect(label).to include("Full")
      expect(label).not_to include("seats left")
    end

    it "does not count waitlisted RSVPs" do
      create(:rsvp, event: event)
      create(:rsvp, :waitlisted, event: event)
      expect(seats_label).to include("2 of 3 seats left")
    end

    it "shows Full and never a negative number when capacity drops below the going count" do
      create_list(:rsvp, 3, event: event)
      event.update!(capacity: 1)
      label = seats_label
      expect(label).to include("Full")
      expect(label).not_to include("-2")
    end

    it "loads the going counts of every listed event in a single rsvps query" do
      others = create_list(:event, 3, capacity: 5)
      others.each { create(:rsvp, event: it) }
      create(:rsvp, event: event)

      rsvp_queries = []
      count_rsvps = ->(*, payload) { rsvp_queries << payload[:sql] if payload[:sql].include?('FROM "rsvps"') }
      ActiveSupport::Notifications.subscribed(count_rsvps, "sql.active_record") { get events_path }

      expect(rsvp_queries.size).to eq(1)
      expect(response.body).to include("2 of 3 seats left", "4 of 5 seats left")
    end
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

  describe "attendee list" do
    let(:event) { create(:event, organizer: organizer, capacity: 2) }
    let(:marko) { create(:user, name: "Marko Horvat") }
    let(:attendees) { [ marko, create(:user, name: "Iva Babić"), create(:user, name: "Luka Perić") ] }
    let(:email_address) { /person\d+@gather\.test|#{Regexp.escape(organizer.email_address)}/ }

    before { attendees.each { event.rsvp(it) } }

    it "shows the organizer who is going and who is waiting, in line order" do
      sign_in organizer
      get event_path(event)

      expect(response.body).to include("Going (2)", "Waitlist (1)")
      expect(response.body).to match(/Marko Horvat.*Iva Babić.*Waitlist \(1\).*Luka Perić.*#1/m)
    end

    it "moves the promoted person to Going after a cancellation" do
      event.rsvp_for(marko).destroy!
      sign_in organizer
      get event_path(event)

      expect(response.body).to include("Going (2)", "Waitlist (0)")
      expect(response.body).to match(/Iva Babić.*Luka Perić.*Waitlist \(0\)/m)
    end

    it "shows the list to nobody but the organizer" do
      sign_in marko
      get event_path(event)
      expect(response.body).not_to include("Going (", "Waitlist (", "Iva Babić", "Luka Perić")

      delete session_path
      get event_path(event)
      expect(response.body).not_to include("Going (", "Waitlist (", "Marko Horvat", "Iva Babić", "Luka Perić")
    end

    it "renders no email addresses, not even for the organizer" do
      sign_in organizer
      get event_path(event)
      expect(response.body).not_to match(email_address)

      sign_in marko
      get event_path(event)
      expect(response.body).not_to match(email_address)
    end

    it "offers the organizer no controls to remove or reorder people" do
      sign_in organizer
      get event_path(event)
      attendees_html = response.body[/<section[^>]*id="attendees".*?<\/section>/m]

      expect(attendees_html).to be_present
      expect(attendees_html).not_to match(/<form|<button|<a /)
    end
  end

  describe "comments" do
    let(:marko) { create(:user, name: "Marko Horvat") }

    def comments_section
      get event_path(event)
      Nokogiri::HTML(response.body).at_css("section#comments")
    end

    it "shows guests every comment with its author, posted time and body, in the main column below About this event" do
      create(:comment, event: event, user: marko, body: "Is there parking nearby?")
      create(:comment, event: event, user: organizer, body: "Yes, behind the building.")

      section = comments_section
      expect(section.at_css("h2").text).to eq("Comments (2)")
      expect(section.text).to include("Marko Horvat", "Is there parking nearby?", "Ana Kovač", "Yes, behind the building.")
      expect(section.css("time").size).to eq(2)
      expect(Nokogiri::HTML(response.body).at_css(".event__main > .event__description + section#comments")).to be_present
      expect(Nokogiri::HTML(response.body).at_css("#event-facts #comments")).to be_nil
    end

    it "lists comments oldest first" do
      create(:comment, event: event, body: "Second", created_at: 1.hour.ago)
      create(:comment, event: event, body: "First", created_at: 2.hours.ago)
      create(:comment, event: event, body: "Third", created_at: 1.hour.ago)

      expect(comments_section.css(".comment p:not(.comment__meta)").map(&:text)).to eq(%w[ First Second Third ])
    end

    it "shows an empty state when there are no comments" do
      section = comments_section
      expect(section.at_css("h2").text).to eq("Comments (0)")
      expect(section.text).to include("No comments yet. Ask a question.")
      expect(section.at_css("ol")).to be_nil
    end

    it "shows the posted time in a time element with an ISO 8601 datetime" do
      posted_at = Time.zone.local(2026, 9, 30, 15, 19, 42)
      create(:comment, event: event, created_at: posted_at)

      time = comments_section.at_css("time")
      expect(time.text).to eq("30 September 2026 · 15:19")
      expect(time["datetime"]).to eq(posted_at.iso8601)
    end

    it "shows Someone for an author whose name is blank" do
      create(:comment, event: event, user: marko)
      marko.update_column(:name, "")

      expect(comments_section.at_css(".comment__meta strong").text).to eq("Someone")
    end

    it "shows HTML in the body as escaped text" do
      create(:comment, event: event, body: %(<script>alert(1)</script> <a href="javascript:alert(1)">x</a>))

      comment = comments_section.at_css(".comment")
      expect(comment.css("script, a")).to be_empty
      expect(comment.text).to include(%(<script>alert(1)</script> <a href="javascript:alert(1)">x</a>))
      expect(response.body).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
    end

    it "keeps line breaks in the body" do
      create(:comment, event: event, body: "First line\nSecond line\n\nNew paragraph")

      body = comments_section.at_css(".comment__body")
      expect(body.css("p").map { it.text.squish }).to eq([ "First line Second line", "New paragraph" ])
      expect(body.css("br").size).to eq(1)
    end

    it "loads comments in one query and authors in a fixed number of queries" do
      count_queries = lambda do
        queries = []
        record = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
        ActiveSupport::Notifications.subscribed(record, "sql.active_record") { get event_path(event) }
        [ queries.grep(/\bFROM "comments"/).size, queries.grep(/\bFROM "users"/).size ]
      end

      create(:comment, event: event)
      comments_with_one, users_with_one = count_queries.call

      create_list(:comment, 9, event: event)
      comments_with_ten, users_with_ten = count_queries.call

      expect(response.body).to include("Comments (10)")
      expect([ comments_with_one, comments_with_ten ]).to eq([ 1, 1 ])
      expect(users_with_ten).to eq(users_with_one)
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
