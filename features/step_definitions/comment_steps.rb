WHITESPACE_BODIES = { "empty" => "", "spaces" => "   ", "newlines and tabs" => "\n\t \r\n" }.freeze

def ids_of(name_or_title)
  (@ids ||= {})[name_or_title] ||= (Event.find_by(title: name_or_title) || person(name_or_title)).id
end

def write_comment(name, title, body)
  @comment = event_named(title).comments.new(user: person(name), body: body)
end

When("{string} writes {string} on {string}") do |name, body, title|
  write_comment(name, title, body)
end

When("{string} writes a body of {string} on {string}") do |name, kind, title|
  write_comment(name, title, WHITESPACE_BODIES.fetch(kind))
end

When("{string} writes a {int}-character comment on {string}") do |name, length, title|
  write_comment(name, title, "a" * length)
end

Given("{string} commented {string} on {string}") do |name, body, title|
  create(:comment, event: event_named(title), user: person(name), body: body)
  ids_of(name)
  ids_of(title)
end

Given("these comments on {string}:") do |title, table|
  table.hashes.each do |row|
    create(:comment, event: event_named(title), user: person(row["author"]), body: row["body"],
      created_at: row["hours ago"].to_i.hours.ago.beginning_of_minute)
  end
end

When("the event {string} is destroyed") do |title|
  ids_of(title)
  event_named(title).destroy!
end

Then("the comment is valid") do
  expect(@comment).to be_valid
end

Then("the comment is invalid with {string}") do |message|
  expect(@comment).not_to be_valid
  expect(@comment.errors.full_messages).to eq([ message ])
end

Then("the comment body is {string}") do |body|
  expect(@comment.body).to eq(body)
end

Then("the comments on {string} are listed as:") do |title, table|
  expect(event_named(title).comments.oldest_first.map(&:body)).to eq(table.raw.flatten)
end

Then("no comments remain on the event {string}") do |title|
  expect(Comment.where(event_id: ids_of(title))).to be_empty
end

Then("no comments by {string} remain") do |name|
  expect(Comment.where(user_id: ids_of(name))).to be_empty
end

Then("the event {string} no longer exists") do |title|
  expect(Event.exists?(ids_of(title))).to be(false)
end
