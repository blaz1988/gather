def attempt
  @error = nil
  yield
rescue ActiveRecord::StatementInvalid => e
  @error = e
end

def column_list(names)
  names.split(",").map(&:strip)
end

Given("the database is migrated") do
  expect(ActiveRecord::Base.connection_pool.migration_context.needs_migration?).to be(false)
  expect(db.table_exists?(:rsvps)).to be(true)
end

Given("{string} has a {string} rsvps row for {string}") do |name, status, title|
  insert_rsvp(event_id: event_named(title).id, user_id: person(name).id, status: status)
end

Given("{string} has a session") do |name|
  person(name).sessions.create!
end

When("I insert a {string} rsvps row for {string} and {string}") do |status, name, title|
  attempt { insert_rsvp(event_id: event_named(title).id, user_id: person(name).id, status: status) }
end

When("I insert a {string} rsvps row for a missing event") do |status|
  attempt { insert_rsvp(event_id: 0, user_id: person("Marko Horvat").id, status: status) }
end

When("I insert a {string} rsvps row for a missing person") do |status|
  attempt { insert_rsvp(event_id: Event.first.id, user_id: 0, status: status) }
end

When("I delete the event {string} directly in the database") do |title|
  attempt { db.execute("DELETE FROM events WHERE id = #{event_named(title).id}") }
end

When("I delete the person {string} directly in the database") do |name|
  attempt { db.execute("DELETE FROM users WHERE id = #{person(name).id}") }
end

When("I roll back the rsvps migration") do
  @snapshot = table_snapshot(:events, :users, :sessions)
  run_create_rsvps(:down)
end

Then("the rsvps table has NOT NULL columns {string}") do |names|
  columns = db.columns(:rsvps).index_by(&:name)
  column_list(names).each do |name|
    expect(columns.fetch(name).null).to be(false), "expected rsvps.#{name} to be NOT NULL"
  end
end

Then("the rsvps status column has no default") do
  expect(db.columns(:rsvps).find { |c| c.name == "status" }.default).to be_nil
end

Then(/^the (?:insert|delete) fails with (\S+)$/) do |error_class|
  expect(@error).to be_a(error_class.constantize)
end

Then("the insert fails the check constraint {string}") do |name|
  expect(@error).to be_a(ActiveRecord::StatementInvalid)
  expect(@error.message).to include("CHECK constraint failed: #{name}")
end

Then("the rsvps index {string} is unique on {string}") do |name, columns|
  expect(rsvps_index(name)).to have_attributes(columns: column_list(columns), unique: true)
end

Then("the rsvps index {string} is on {string}") do |name, columns|
  expect(rsvps_index(name)).to have_attributes(columns: column_list(columns))
end

Then("no rsvps foreign key cascades on delete") do
  expect(db.foreign_keys(:rsvps).map(&:to_table)).to contain_exactly("events", "users")
  expect(db.foreign_keys(:rsvps).map(&:on_delete).compact).to be_empty
end

Then("there is {int} rsvps row(s)") do |count|
  expect(db.select_value("SELECT COUNT(*) FROM rsvps")).to eq(count)
end

Then("the rsvps table does not exist") do
  expect(db.table_exists?(:rsvps)).to be(false)
end

Then("the events, users and sessions tables are unchanged") do
  expect(table_snapshot(:events, :users, :sessions)).to eq(@snapshot)
end

After("@pd-1-t1") do
  run_create_rsvps(:up) unless db.table_exists?(:rsvps)
end
