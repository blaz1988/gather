def delete_comment_by(name, confirm)
  form = comments_section.find(".comment", text: name).find(:xpath, ".//form[.//button[normalize-space()='Delete']]")
  expect(form["data-turbo-confirm"]).to eq(confirm)
  form.click_button "Delete"
end

def capturing_log
  log = StringIO.new
  logger = ActiveSupport::Logger.new(log)
  Rails.logger.broadcast_to(logger)
  yield
  log.string
ensure
  Rails.logger.stop_broadcasting_to(logger)
end

Given("{string} commented {int} more time(s) on {string}") do |name, count, title|
  create_list(:comment, count, event: event_named(title), user: person(name))
end

When("I click \"Delete\" on the comment by {string} and confirm {string}") do |name, confirm|
  delete_comment_by(name, confirm)
end

When("I click \"Delete\" on the comment by {string} and confirm {string} while capturing the log") do |name, confirm|
  @deleted_comment_id = Comment.find_by!(user: person(name)).id
  @log = capturing_log { delete_comment_by(name, confirm) }
end

When("I send a DELETE for the comment by {string} to {string}") do |name, title|
  comment = Comment.find_by!(user: person(name))
  page.driver.submit :delete, event_comment_path(event_named(title), comment), {}
end

Then("I should see {int} {string} button(s)") do |count, label|
  expect(page).to have_button(label, exact: true, count: count)
end

Then("the log has the line for deleting the comment by {string} on {string}, deleted by {string}") do |author, title, deleter|
  expect(Comment.exists?(@deleted_comment_id)).to be(false)
  expect(@log).to include(
    "Comment deleted: comment_id=#{@deleted_comment_id} event_id=#{event_named(title).id} " \
    "author_id=#{person(author).id} deleted_by=#{person(deleter).id}"
  )
end
