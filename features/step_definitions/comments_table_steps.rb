# Reuses attempt, column_list and the insert/delete failure steps from rsvps_table_steps.rb.

ACCENTED_BODY_UNIT = "Čćž é 🎉 ".freeze

def insert_comment_as(name, title, body)
  attempt { insert_comment(event_id: event_named(title).id, user_id: person(name).id, body: body) }
end

Given("the comments migration has run") do
  expect(ActiveRecord::Base.connection_pool.migration_context.needs_migration?).to be(false)
  expect(db.table_exists?(:comments)).to be(true)
end

Given("{string} has a comments row on {string}") do |name, title|
  insert_comment(event_id: event_named(title).id, user_id: person(name).id)
end

When("I insert a comments row for a missing event") do
  attempt { insert_comment(event_id: 0, user_id: person("Marko Horvat").id) }
end

When("I insert a comments row for a missing person") do
  attempt { insert_comment(event_id: Event.first.id, user_id: 0) }
end

When("{string} inserts a comments row on {string} with the body {string}") do |name, title, body|
  insert_comment_as(name, title, body)
end

When("{string} inserts a comments row on {string} with a {int}-character body") do |name, title, length|
  insert_comment_as(name, title, "a" * length)
end

When("{string} inserts a comments row on {string} with a {int}-character body of accented letters and emoji") do |name, title, length|
  body = (ACCENTED_BODY_UNIT * length).first(length)
  expect(body.bytesize).to be > length
  insert_comment_as(name, title, body)
end

When("I roll back the comments migration") do
  @snapshot = table_snapshot(:events, :users, :rsvps, :sessions)
  run_create_comments(:down)
end

Then("the comments table has NOT NULL columns {string}") do |names|
  columns = db.columns(:comments).index_by(&:name)
  column_list(names).each do |name|
    expect(columns.fetch(name).null).to be(false), "expected comments.#{name} to be NOT NULL"
  end
end

Then("the comments body column has no default") do
  expect(db.columns(:comments).find { |c| c.name == "body" }.default).to be_nil
end

Then("the insert succeeds") do
  expect(@error).to be_nil
end

Then("the comments index {string} is on {string}") do |name, columns|
  expect(comments_index(name)).to have_attributes(columns: column_list(columns))
end

Then("no comments index is on {string} alone") do |column|
  expect(db.indexes(:comments).map(&:columns)).not_to include([ column ])
end

Then("no comments foreign key cascades on delete") do
  expect(db.foreign_keys(:comments).map(&:to_table)).to contain_exactly("events", "users")
  expect(db.foreign_keys(:comments).map(&:on_delete).compact).to be_empty
end

Then("there is {int} comments row(s)") do |count|
  expect(db.select_value("SELECT COUNT(*) FROM comments")).to eq(count)
end

Then("the comments table does not exist") do
  expect(db.table_exists?(:comments)).to be(false)
end

Then("the events, users, rsvps and sessions tables are unchanged") do
  expect(table_snapshot(:events, :users, :rsvps, :sessions)).to eq(@snapshot)
end

After("@pd-3-t1") do
  run_create_comments(:up) unless db.table_exists?(:comments)
end
