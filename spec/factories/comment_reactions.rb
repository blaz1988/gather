FactoryBot.define do
  factory :comment_reaction do
    comment
    user
    kind { "like" }

    trait :dislike do
      kind { "dislike" }
    end
  end
end
