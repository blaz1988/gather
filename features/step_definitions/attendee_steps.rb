def names_in(list_id)
  all("##{list_id} li").map { it.text.sub(/\s*#\d+\z/, "") }
end

Then("I should see {string} followed by {string}") do |heading, list|
  list_id = heading.start_with?("Waitlist") ? "waitlist" : "going-list"
  within("#attendees") do
    expect(page).to have_css("h3", text: heading, exact_text: true)
    expect(names_in(list_id)).to eq(people_in(list))
  end
end

Then("I should see {string} next to {string} on the waitlist") do |position, name|
  expect(page).to have_css("#waitlist li", text: "#{name} #{position}", exact_text: true)
end

Then("I should see no attendee lists") do
  expect(page).to have_no_css("#attendees")
  expect(page).to have_no_content(/Going \(\d+\)|Waitlist \(\d+\)/)
end

Then("I should see no email addresses") do
  expect(page.html).not_to match(/[\w.+-]+@[\w-]+\.[\w.]+/)
end

Then("I should see no controls to remove or reorder people") do
  within("#attendees") do
    expect(page).to have_no_css("form, button, a, input")
  end
end
