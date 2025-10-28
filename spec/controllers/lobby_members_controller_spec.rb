require 'rails_helper'

RSpec.describe LobbyMembersController, type: :controller do
  let(:owner) { create(:user) }
  let(:participant) { create(:user) }
  let(:lobby) { create(:lobby, owner: owner) }

  before do
    allow(controller).to receive(:current_user).and_return(participant)
    allow(controller).to receive(:authenticate_user!).and_return(true)
    session[:user_id] = participant.id
  end

  describe "POST #create_by_code" do
    context "with a valid lobby code" do
      it "adds the user to the lobby" do
        expect {
          post :create_by_code, params: { lobby_code: lobby.lobby_code }
        }.to change(LobbyMember, :count).by(1)
      end

      it "redirects to the lobby's show page" do
        post :create_by_code, params: { lobby_code: lobby.lobby_code }
        expect(response).to redirect_to(lobby_path(lobby))
      end
    end

    context "with an invalid lobby code" do
      it "does not add the user to the lobby" do
        expect {
          post :create_by_code, params: { lobby_code: "INVALID" }
        }.not_to change(LobbyMember, :count)
      end

      it "redirects to the lobbies index page with an alert" do
        post :create_by_code, params: { lobby_code: "INVALID" }
        expect(flash[:alert]).to eq("Invalid lobby code. Please try again.")
        expect(response).to redirect_to(lobbies_path)
      end
    end

    context "when user is already a member" do
      before do
        create(:lobby_member, lobby: lobby, user: owner)
        lobby.users << participant
      end

      it "does not create a duplicate membership" do
        expect {
          post :create_by_code, params: { lobby_code: lobby.lobby_code }
        }.not_to change(LobbyMember, :count)
      end

      it "redirects to the lobbies index page with an alert" do
        post :create_by_code, params: { lobby_code: lobby.lobby_code }
        expect(flash[:alert]).to eq("You are already in this lobby.")
        expect(response).to redirect_to(lobbies_path)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:member) { create(:lobby_member, user: participant, lobby: lobby) }

    it "removes the current user's membership from the lobby" do
      expect {
        delete :destroy, params: { id: lobby.id }
      }.to change(LobbyMember, :count).by(-1)
    end

    it "redirects to the lobbies index page" do
      delete :destroy, params: { id: lobby.id }
      expect(response).to redirect_to(lobbies_path)
    end
  end
end