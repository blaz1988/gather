# Reuses attempt, column_list, "the insert succeeds" and the insert/delete failure steps
# from rsvps_table_steps.rb and comments_table_steps.rb.

def comment_id_by(name)
  db.select_value(ActiveRecord::Base.sanitize_sql_array([ "SELECT id FROM comments WHERE user_id = ? ORDER BY id LIMIT 1", person(name).id ]))
end

Given("the comment_reactions migration has run") do
  expect(ActiveRecord::Base.connection_pool.migration_context.needs_migration?).to be(false)
  expect(db.table_exists?(:comment_reactions)).to be(true)
end

Given("{string} has a {string} comment_reactions row on the comment by {string}") do |name, kind, author|
  insert_comment_reaction(comment_id: comment_id_by(author), user_id: person(name).id, kind: kind)
end

When("I insert a comment_reactions row for a missing comment") do
  attempt { insert_comment_reaction(comment_id: 0, user_id: person("Marko Horvat").id) }
end

When("I insert a comment_reactions row for a missing person") do
  attempt { insert_comment_reaction(comment_id: comment_id_by("Ana Kovač"), user_id: 0) }
end

When("{string} inserts a {string} comment_reactions row on the comment by {string}") do |name, kind, author|
  attempt { insert_comment_reaction(comment_id: comment_id_by(author), user_id: person(name).id, kind: kind) }
end

When("I delete the comment by {string} directly in the database") do |author|
  attempt { db.execute("DELETE FROM comments WHERE id = #{comment_id_by(author)}") }
end

When("I destroy the event {string}") do |title|
  attempt { event_named(title).destroy! }
end

When("I destroy the person {string}") do |name|
  attempt { person(name).destroy! }
end

When("I roll back the comment_reactions migration") do
  @snapshot = table_snapshot(:comments, :events, :users, :rsvps, :sessions)
  run_create_comment_reactions(:down)
end

Then(/^the (?:delete|destroy) succeeds$/) do
  expect(@error).to be_nil
end

Then("the comment_reactions table has NOT NULL columns {string}") do |names|
  columns = db.columns(:comment_reactions).index_by(&:name)
  column_list(names).each do |name|
    expect(columns.fetch(name).null).to be(false), "expected comment_reactions.#{name} to be NOT NULL"
  end
end

Then("the comment_reactions kind column has no default") do
  expect(db.columns(:comment_reactions).find { |c| c.name == "kind" }.default).to be_nil
end

Then("the comment_reactions index {string} is unique on {string}") do |name, columns|
  expect(comment_reactions_index(name)).to have_attributes(columns: column_list(columns), unique: true)
end

Then("the comment_reactions index {string} is on {string}") do |name, columns|
  expect(comment_reactions_index(name)).to have_attributes(columns: column_list(columns))
end

Then("no comment_reactions index is on {string} alone") do |column|
  expect(db.indexes(:comment_reactions).map(&:columns)).not_to include([ column ])
end

Then("there is/are {int} comment_reactions row(s)") do |count|
  expect(comment_reactions_count).to eq(count)
end

Then("{string} still has a {string} comment_reactions row on the comment by {string}") do |name, kind, author|
  expect(db.select_rows("SELECT user_id, kind FROM comment_reactions WHERE comment_id = #{comment_id_by(author)}"))
    .to eq([ [ person(name).id, kind ] ])
end

Then("the comment_reactions table does not exist") do
  expect(db.table_exists?(:comment_reactions)).to be(false)
end

Then("the comments, events, users, rsvps and sessions tables are unchanged") do
  expect(table_snapshot(:comments, :events, :users, :rsvps, :sessions)).to eq(@snapshot)
end

After("@pd-4-t2") do
  run_create_comment_reactions(:up) unless db.table_exists?(:comment_reactions)
end
