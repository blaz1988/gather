# Demo data. Every account's password is "password123".
password = "password123"

people = {
  ana: "Ana Kovač",
  marko: "Marko Horvat",
  ivan: "Ivan Blažević",
  petra: "Petra Novak",
  luka: "Luka Babić",
  maja: "Maja Jurić"
}.to_h do |key, name|
  user = User.find_or_initialize_by(email_address: "#{key}@gather.test")
  user.update!(name: name, password: password)
  [ key, user ]
end

[
  {
    title: "Ruby Zagreb Meetup #42",
    organizer: people[:ana],
    starts_at: 9.days.from_now.change(hour: 18),
    venue: "Rubycode HQ, Savska cesta 32, Zagreb",
    capacity: 3,
    description: "Two talks and pizza. Marko shows how the team moved a 10-year-old app to Rails 8, " \
                 "and Petra walks through Solid Queue in production.\n\nSeats are limited, the room is small."
  },
  {
    title: "Hotwire workshop: Turbo Streams in practice",
    organizer: people[:marko],
    starts_at: 16.days.from_now.change(hour: 17, min: 30),
    venue: "Impact Hub Zagreb",
    capacity: 20,
    description: "A hands-on evening. Bring a laptop with Ruby 3.4 and Rails 8.1 installed."
  },
  {
    title: "Rails upgrade clinic",
    organizer: people[:ivan],
    starts_at: 23.days.from_now.change(hour: 18),
    venue: "Online",
    capacity: 50,
    description: "Stuck on an upgrade? Bring your Gemfile.lock and questions."
  }
].each do |attributes|
  Event.find_or_initialize_by(title: attributes[:title]).update!(attributes)
end

puts "Seeded #{User.count} people and #{Event.count} events."
