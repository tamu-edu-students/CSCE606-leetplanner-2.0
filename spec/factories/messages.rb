FactoryBot.define do
  factory :message do
    body { "Hello world" }
    association :user
    association :lobby
  end
end
