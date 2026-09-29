# Shared steps. People are found or created by name; everyone's password is "password123".

def person(name)
  User.find_by(name: name) || create(:user, name: name)
end

def event_named(title)
  Event.find_by!(title: title)
end

Given("a person named {string}") do |name|
  person(name)
end

Given("I am signed in as {string}") do |name|
  user = person(name)
  visit new_session_path
  fill_in "Email", with: user.email_address
  fill_in "Password", with: "password123"
  click_button "Sign in"
  expect(page).to have_content(name)
end

Given("I am not signed in") do
  visit root_path
end

Given("{string} organizes {string} with {int} seat(s)") do |name, title, capacity|
  create(:event, title: title, organizer: person(name), capacity: capacity)
end

When("I open the event {string}") do |title|
  visit event_path(event_named(title))
end

When("I visit the events page") do
  visit events_path
end

When("I click {string}") do |label|
  click_on label
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should not see {string}") do |text|
  expect(page).to have_no_content(text)
end
