Given("{string} commented {string} on {string} at {string}") do |name, body, title, posted_at|
  create(:comment, event: event_named(title), user: person(name), body: body, created_at: Time.zone.parse(posted_at))
end

Given("{string} commented on {string}:") do |name, title, body|
  create(:comment, event: event_named(title), user: person(name), body: body)
end

Given("{int} more person/people commented on {string}") do |count, title|
  create_list(:comment, count, event: event_named(title))
end

Given("{string} has a blank name, set with update_column") do |name|
  person(name).update_column(:name, "")
end

def comments_section
  find("section#comments")
end

Then("the comments are listed as:") do |table|
  authors_and_bodies = comments_section.all(".comment").map do |comment|
    [ comment.find(".comment__meta strong").text, comment.find(".comment__body").text ]
  end
  expect(authors_and_bodies).to eq(table.rows)
end

Then("the comment by {string} was posted at {string} in a time element dated {string}") do |name, text, datetime|
  comment = comments_section.find(".comment", text: name)
  expect(comment).to have_css("time[datetime='#{datetime}']", exact_text: text)
end

Then("the comment by {string} reads:") do |name, body|
  expect(comments_section.find(".comment", text: name).find(".comment__body").text).to eq(body)
end

Then("the comment by {string} has the paragraphs:") do |name, table|
  paragraphs = comments_section.find(".comment", text: name).all(".comment__body p").map { it.text.squish }
  expect(paragraphs).to eq(table.raw.flatten)
end

Then("the comments section has no script or link elements") do
  expect(comments_section.find("#comments-list")).to have_no_css("script, a", visible: :all)
end

When("I note how many queries ran against users") do
  @noted_users_queries = @queries.grep(/\bFROM "users"/).size
end

Then("the same number of queries ran against users as noted") do
  expect(@queries.grep(/\bFROM "users"/).size).to eq(@noted_users_queries)
end
