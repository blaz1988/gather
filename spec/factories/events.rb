FactoryBot.define do
  factory :event do
    sequence(:title) { |n| "Meetup ##{n}" }
    description { "Talks and pizza." }
    starts_at { 1.week.from_now }
    venue { "Rubycode HQ" }
    capacity { 30 }
    organizer factory: :user
  end
end
