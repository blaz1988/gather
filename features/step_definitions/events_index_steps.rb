Given("{string} is on the waitlist for {string}") do |name, title|
  create(:rsvp, :waitlisted, event: event_named(title), user: person(name))
end

def counting_queries(&)
  @queries = []
  record = ->(*, payload) { @queries << payload[:sql] unless payload[:name] == "SCHEMA" }
  ActiveSupport::Notifications.subscribed(record, "sql.active_record", &)
end

When("I visit the events page while counting queries") do
  counting_queries { visit events_path }
end

When("I open the event {string} while counting queries") do |title|
  path = event_path(event_named(title))
  counting_queries { visit path }
end

Then("{int} query/queries ran against {word}") do |count, table|
  expect(@queries.grep(/\bFROM "#{table}"/).size).to eq(count)
end
