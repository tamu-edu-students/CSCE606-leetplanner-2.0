require 'rails_helper'

RSpec.describe Lobby, type: :model do
  describe "associations and users" do
    let(:owner) { create(:user, first_name: "Alice") }
    let(:lobby) { create(:lobby, owner: owner) }
    let(:user_bob) { create(:user, first_name: "Bob") }
    let(:user_charlie) { create(:user, first_name: "Charlie") }

    before do
      # The owner is added as a member upon lobby creation in the controller
      create(:lobby_member, lobby: lobby, user: owner)
    end

    it "includes the owner in its list of users" do
      expect(lobby.users).to include(owner)
    end

    it "returns all users who have joined the lobby" do
      lobby.users << [ user_bob, user_charlie ]

      expect(lobby.users.count).to eq(3)
      expect(lobby.users).to include(owner, user_bob, user_charlie)
    end

    it "generates a lobby_code on creation" do
      expect(lobby.lobby_code).to be_present
      expect(lobby.lobby_code.length).to eq(6)
    end
  end
end
