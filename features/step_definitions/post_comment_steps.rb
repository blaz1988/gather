# Reuses WHITESPACE_BODIES from comment_steps.rb and the sign-in and 404 steps from rsvp_steps.rb.

def comment_box
  find("form#new-comment textarea[name='comment[body]']")
end

def post_comment(body)
  comment_box.set(body)
  click_button "Post comment"
end

def submit_comment(event_id, params)
  page.driver.submit :post, event_comments_path(event_id:), params
end

When("I post the comment {string}") do |body|
  post_comment(body)
end

When("I post a comment with a body of {string}") do |kind|
  post_comment(WHITESPACE_BODIES.fetch(kind))
end

When("I send a comment {string} to {string}") do |body, title|
  submit_comment(event_named(title).id, comment: { body: })
end

When("I send a comment {string} to an unknown event") do |body|
  submit_comment(0, comment: { body: })
end

When("I send a {int}-character comment to {string}") do |length, title|
  submit_comment(event_named(title).id, comment: { body: "a" * length })
end

When("I send a comment to {string} as {string} on {string} created at {string}") do |title, name, other_title, created_at|
  forged = { user_id: person(name).id, event_id: event_named(other_title).id, created_at: }
  submit_comment(event_named(title).id, forged.merge(comment: forged.merge(body: "Is there parking nearby?")))
end

Then("I am on the comments section of {string}") do |title|
  expect(URI(page.current_url).request_uri).to eq(event_path(event_named(title)))
  expect(URI(page.current_url).fragment).to eq("comments")
end

Then("I should see the comment form") do
  expect(page).to have_css("form#new-comment")
  expect(page).to have_button("Post comment")
end

Then("I should not see the comment form") do
  expect(page).to have_no_css("form#new-comment")
  expect(page).to have_no_field("comment[body]")
end

Then("the comment box is required with a maxlength of {int}") do |length|
  expect(comment_box[:required]).to be_truthy
  expect(comment_box[:maxlength]).to eq(length.to_s)
end

Then("the only comment is by {string} on {string}, posted just now") do |name, title|
  expect(Comment.sole).to have_attributes(user: person(name), event: event_named(title),
    created_at: be_within(1.minute).of(Time.current))
end
