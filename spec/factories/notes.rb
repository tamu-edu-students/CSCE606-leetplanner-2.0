FactoryBot.define do
  factory :note do
    content { "Sample note content" }
    association :lobby
    association :user
  end
end