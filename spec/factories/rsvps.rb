FactoryBot.define do
  factory :rsvp do
    event
    user
    status { "going" }

    trait :waitlisted do
      status { "waitlisted" }
    end
  end
end
