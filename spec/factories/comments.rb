FactoryBot.define do
  factory :comment do
    association :event
    association :user
    body { "Is there parking nearby?" }
  end
end
