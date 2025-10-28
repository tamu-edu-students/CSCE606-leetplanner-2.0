FactoryBot.define do
  factory :lobby_member do
    association :user
    association :lobby
  end
end