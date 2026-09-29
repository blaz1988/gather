FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Person #{n}" }
    sequence(:email_address) { |n| "person#{n}@gather.test" }
    password { "password123" }
  end
end
