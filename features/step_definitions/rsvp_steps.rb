def people_in(list)
  list.split(/, | and /)
end

def rsvp_of(name, title)
  event_named(title).rsvps.find_by!(user: person(name))
end

When("{string} RSVP(s) to {string}") do |name, title|
  @returned = event_named(title).rsvp(person(name))
end

When("{string} RSVP(s) to {string} in turn") do |list, title|
  people_in(list).each { event_named(title).rsvp(person(it)) }
end

Given("{string} has RSVPed to {string}") do |name, title|
  @first = event_named(title).rsvp(person(name))
end

When("{string} RSVPs to {string} again") do |name, title|
  @first ||= rsvp_of(name, title)
  @returned = event_named(title).rsvp(person(name))
end

When("{int} people RSVP to {string} at the same time") do |count, title|
  event = event_named(title)
  @racers = Array.new(count) { |n| person("Racer #{n + 1}") }
  start = Concurrent::CountDownLatch.new(1)

  threads = @racers.map do |user|
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        start.wait
        Event.find(event.id).rsvp(user)
      end
    end
  end
  start.count_down
  threads.each(&:join)
end

When("{string} cancels their RSVP to {string}") do |name, title|
  rsvp_of(name, title).destroy!
end

When("the person {string} is deleted") do |name|
  person(name).destroy!
end

When("the capacity of {string} is lowered to {int}") do |title, capacity|
  event_named(title).update!(capacity: capacity)
end

Given("{string} started an hour ago") do |title|
  event_named(title).update!(starts_at: 1.hour.ago)
end

Then("{string} has {int} seat(s) left") do |title, count|
  expect(event_named(title).seats_left).to eq(count)
end

Then("{string} is full") do |title|
  expect(event_named(title)).to be_full
end

Then("{string} is not full") do |title|
  expect(event_named(title)).not_to be_full
end

Then("{string} has an empty waitlist") do |title|
  expect(event_named(title).waitlist_count).to eq(0)
end

Then("{string} is going to {string} with no waitlist position") do |name, title|
  rsvp = rsvp_of(name, title)
  expect(rsvp).to be_going
  expect(rsvp.waitlist_position).to be_nil
end

Then('{string} is #{int} on the waitlist for {string}') do |name, position, title|
  rsvp = rsvp_of(name, title)
  expect(rsvp).to be_waitlisted
  expect(rsvp.waitlist_position).to eq(position)
end

Then("the same RSVP is returned") do
  expect(@returned).to eq(@first)
end

Then("no RSVP is returned") do
  expect(@returned).to be_nil
end

Then("{string} has {int} going and {int} waitlisted") do |title, going, waitlisted|
  rsvps = event_named(title).rsvps
  expect([ rsvps.going.count, rsvps.waitlisted.count ]).to eq([ going, waitlisted ])
end

Then("exactly {int} of them is going and {int} are waitlisted") do |going, waitlisted|
  expect(Rsvp.where(user: @racers).group(:status).count).to eq("going" => going, "waitlisted" => waitlisted)
end

Then("there are no RSVPs") do
  expect(Rsvp.count).to eq(0)
end
