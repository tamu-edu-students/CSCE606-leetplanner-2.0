FactoryBot.define do
  factory :lobby do
    name { Faker::Company.catch_phrase }
    description { Faker::Lorem.sentence }
    association :owner, factory: :user
  end
end