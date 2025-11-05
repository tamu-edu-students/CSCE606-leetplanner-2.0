require 'rails_helper'

RSpec.describe Note, type: :model do
  describe "associations" do
    it { should belong_to(:lobby) }
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:content) }

    it "validates uniqueness of lobby_id" do
      lobby = create(:lobby)
      user = create(:user)
      create(:note, lobby: lobby, user: user, content: "Original note")

      new_note = build(:note, lobby: lobby, user: user, content: "Duplicate note")
      expect(new_note).not_to be_valid
      expect(new_note.errors[:lobby_id]).to include("has already been taken")
    end
  end
end
