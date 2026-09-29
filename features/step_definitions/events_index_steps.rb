Given("{string} is on the waitlist for {string}") do |name, title|
  create(:rsvp, :waitlisted, event: event_named(title), user: person(name))
end

When("I visit the events page while counting queries") do
  @queries = []
  record = ->(*, payload) { @queries << payload[:sql] unless payload[:name] == "SCHEMA" }
  ActiveSupport::Notifications.subscribed(record, "sql.active_record") { visit events_path }
end

Then("{int} query/queries ran against {word}") do |count, table|
  expect(@queries.grep(/\bFROM "#{table}"/).size).to eq(count)
end
