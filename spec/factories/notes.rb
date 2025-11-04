FactoryBot.define do
  factory :note do
    content { "Some note content" }
    association :lobby
    association :user
  end
end
