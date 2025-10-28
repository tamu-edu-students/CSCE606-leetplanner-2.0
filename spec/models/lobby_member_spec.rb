require 'rails_helper'

RSpec.describe LobbyMember, type: :model do
  let(:user) { create(:user) }
  let(:lobby) { create(:lobby) }

  describe "validations" do
    it "is valid with a user and a lobby" do
      member = build(:lobby_member, user: user, lobby: lobby)
      expect(member).to be_valid
    end

    it "is invalid if a user is added to the same lobby twice" do
      create(:lobby_member, user: user, lobby: lobby) # First membership
      duplicate_member = build(:lobby_member, user: user, lobby: lobby) # Second attempt
      
      expect(duplicate_member).not_to be_valid
      expect(duplicate_member.errors[:user_id]).to include("is already in this lobby")
    end
  end

  describe "permissions" do
    it "defaults all permissions to false upon creation" do
      member = build(:lobby_member)
      expect(member.can_draw).to be_falsey
      expect(member.can_edit_notes).to be_falsey
    end
    
    it "can update the can_draw permission" do
      member = create(:lobby_member, can_draw: false)
      member.update(can_draw: true)
      expect(member.reload.can_draw).to be_truthy
    end

    it "can update the can_edit_notes permission" do
      member = create(:lobby_member, can_edit_notes: true)
      member.update(can_edit_notes: false)
      expect(member.reload.can_edit_notes).to be_falsey
    end
  end
end