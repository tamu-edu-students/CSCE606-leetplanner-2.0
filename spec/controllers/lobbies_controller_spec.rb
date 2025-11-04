require 'rails_helper'

RSpec.describe LobbiesController, type: :controller do

  let!(:user) { User.create!(
    netid: "specuser",
    email: "specuser@example.com",
    first_name: "Spec",
    last_name: "User"
  ) }
  
  let!(:other_user) { User.create!(
    netid: "otheruser",
    email: "other@example.com",
    first_name: "Other",
    last_name: "User"
  ) }

  # Create a set of lobbies to test the 'index' action's logic
  let!(:joined_lobby) { 
    Lobby.create!(name: "Joined Private", owner: other_user, private: true) 
  }
  let!(:public_unjoined_lobby) { 
    Lobby.create!(name: "Public", owner: other_user, private: false) 
  }
  let!(:private_unjoined_lobby) { 
    Lobby.create!(name: "Other Private", owner: other_user, private: true) 
  }
  # Make 'user' a member of the 'joined_lobby'
  let!(:membership) { 
    LobbyMember.create!(lobby: joined_lobby, user: user) 
  }

  # A lobby that 'user' owns, for testing edit/update/destroy
  let!(:owned_lobby) { 
    Lobby.create!(name: "Owned Lobby", owner: user) 
  }

  # Valid/invalid attributes for create/update tests
  let(:valid_attributes) {
    { name: "New Lobby Name", description: "A test lobby.", private: false }
  }
  let(:invalid_attributes) {
    { name: "" } # Fails validation
  }
  
  describe "GET #index" do
    before do
      session[:user_id] = user.id # "Log in" the user
      get :index
    end

    it "assigns the correct lobbies to @lobbies" do
      expect(assigns(:lobbies)).to include(joined_lobby)
      expect(assigns(:lobbies)).to include(public_unjoined_lobby)
      expect(assigns(:lobbies)).not_to include(private_unjoined_lobby)
    end
  end

  describe "GET #show" do
    before { session[:user_id] = user.id }

    it "assigns the requested lobby to @lobby" do
      get :show, params: { id: owned_lobby.id }
      expect(assigns(:lobby)).to eq(owned_lobby)
    end
  end

  describe "GET #new" do
    before { session[:user_id] = user.id }
    
    it "assigns a new lobby to @lobby" do
      get :new
      expect(assigns(:lobby)).to be_a_new(Lobby)
    end
  end

  describe "GET #edit" do
    before { session[:user_id] = user.id }

    it "assigns the requested lobby to @lobby" do
      get :edit, params: { id: owned_lobby.id }
      expect(assigns(:lobby)).to eq(owned_lobby)
    end
  end

  describe "POST #create" do
    before { session[:user_id] = user.id }

    context "with valid parameters" do
      it "creates a new Lobby and a LobbyMember for the owner" do
        expect {
          post :create, params: { lobby: valid_attributes }
        }.to change(Lobby, :count).by(1).and change(LobbyMember, :count).by(1)
      end

      it "assigns the current user as the owner" do
        post :create, params: { lobby: valid_attributes }
        expect(Lobby.last.owner).to eq(user)
      end

      it "redirects to the created lobby (HTML)" do
        post :create, params: { lobby: valid_attributes }
        expect(response).to redirect_to(Lobby.last)
      end

      it "returns a :created status (JSON)" do
        post :create, params: { lobby: valid_attributes }, as: :json
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid parameters" do
      it "does not create a new Lobby" do
        expect {
          post :create, params: { lobby: invalid_attributes }
        }.not_to change(Lobby, :count)
      end

      it "renders the 'new' template (HTML)" do
        post :create, params: { lobby: invalid_attributes }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns an :unprocessable_content status (JSON)" do
        post :create, params: { lobby: invalid_attributes }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH #update" do
    before { session[:user_id] = user.id }

    context "with valid parameters" do
      let(:new_attributes) { { name: "A Brand New Name" } }

      it "updates the requested lobby" do
        patch :update, params: { id: owned_lobby.id, lobby: new_attributes }
        expect(owned_lobby.reload.name).to eq("A Brand New Name")
      end

      it "redirects to the lobby (HTML)" do
        patch :update, params: { id: owned_lobby.id, lobby: new_attributes }
        expect(response).to redirect_to(owned_lobby)
      end

      it "returns an :ok status (JSON)" do
        patch :update, params: { id: owned_lobby.id, lobby: new_attributes }, as: :json
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid parameters" do
      it "does not update the lobby" do
        patch :update, params: { id: owned_lobby.id, lobby: invalid_attributes }
        expect(owned_lobby.reload.name).not_to eq("")
      end

      it "renders the 'edit' template (HTML)" do
        patch :update, params: { id: owned_lobby.id, lobby: invalid_attributes }
        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns an :unprocessable_content status (JSON)" do
        patch :update, params: { id: owned_lobby.id, lobby: invalid_attributes }, as: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE #destroy" do
    # Create a lobby and members specifically for the destroy test
    let!(:lobby_to_delete) { Lobby.create!(name: "Delete Me", owner: user) }
    let!(:owner_member) { LobbyMember.create!(lobby: lobby_to_delete, user: user) }
    let!(:other_member) { LobbyMember.create!(lobby: lobby_to_delete, user: other_user) }

    context "as the lobby owner" do
      before { session[:user_id] = user.id }

      it "destroys the lobby and all its members" do
        expect {
          delete :destroy, params: { id: lobby_to_delete.id }
        }.to change(Lobby, :count).by(-1).and change(LobbyMember, :count).by(-2) # Deletes both members
      end

      it "redirects to the lobbies list (HTML)" do
        delete :destroy, params: { id: lobby_to_delete.id }
        expect(response).to redirect_to(lobbies_path)
      end

      it "returns a :no_content status (JSON)" do
        delete :destroy, params: { id: lobby_to_delete.id }, as: :json
        expect(response).to have_http_status(:no_content)
      end
    end

    context "as a non-owner" do
      before { session[:user_id] = other_user.id } # Logged in as 'other_user'

      it "does not destroy the lobby" do
        expect {
          delete :destroy, params: { id: lobby_to_delete.id }
        }.not_to change(Lobby, :count)
      end

      it "redirects with an alert (HTML)" do
        delete :destroy, params: { id: lobby_to_delete.id }
        expect(response).to redirect_to(lobbies_path)
        expect(flash[:alert]).to eq("You are not authorized to destroy this lobby.")
      end

      it "returns a :forbidden status (JSON)" do
        delete :destroy, params: { id: lobby_to_delete.id }, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
