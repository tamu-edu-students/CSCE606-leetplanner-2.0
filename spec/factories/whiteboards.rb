FactoryBot.define do
  factory :whiteboard do
    association :lobby
    name { "Test Whiteboard" }
    description { "Shared whiteboard for testing" }
    svg_data { nil }
    notes { "Initial notes" }
  end
end
