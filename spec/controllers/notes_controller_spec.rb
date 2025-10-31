require 'rails_helper'

# We stub :current_user directly since Devise is not being used.
# We still assume factories are set up (FactoryBot) for user, lobby, etc.

RSpec.describe NotesController, type: :controller do
  # Create users with different roles
  let(:owner) { create(:user) }
  let(:editor_member) { create(:user) }
  let(:viewer_member) { create(:user) }
  let(:other_user) { create(:user) }

  # Create the main lobby owned by 'owner'
  let(:lobby) { create(:lobby, owner: owner) }

  # Create memberships for the lobby
  let!(:editor_lobby_member) do
    create(:lobby_member, lobby: lobby, user: editor_member, can_edit_notes: true)
  end
  let!(:viewer_lobby_member) do
    create(:lobby_member, lobby: lobby, user: viewer_member, can_edit_notes: false)
  end

  # Shared parameters for the nested route
  let(:route_params) { { lobby_id: lobby.id } }

  describe "GET #show" do
    before do
      # 'show' is accessible to everyone, so we'll test with any authenticated user
      # Stub the current_user method
      allow(controller).to receive(:current_user).and_return(other_user)
    end

    context "when note does not exist" do
      it "assigns a new note to @note" do
        get :show, params: route_params
        expect(assigns(:note)).to be_a_new(Note)
        expect(assigns(:note).user).to eq other_user
      end

      it "renders the show template" do
        get :show, params: route_params
        expect(response).to render_template(:show)
      end
    end

    context "when note already exists" do
      let!(:existing_note) { create(:note, lobby: lobby, user: owner, content: "Existing content") }

      it "assigns the existing note to @note" do
        get :show, params: route_params
        expect(assigns(:note)).to eq existing_note
      end

      it "renders the show template" do
        get :show, params: route_params
        expect(response).to render_template(:show)
      end
    end

    it "assigns the correct lobby to @lobby" do
      get :show, params: route_params
      expect(assigns(:lobby)).to eq lobby
    end
  end

  describe "GET #edit" do
    # Test authorization for 'edit'
    context "when user is unauthorized" do
      it "redirects viewer_member" do
        allow(controller).to receive(:current_user).and_return(viewer_member)
        get :edit, params: route_params
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:alert]).to eq "You are not authorized to edit this note"
      end

      it "redirects other_user (non-member)" do
        allow(controller).to receive(:current_user).and_return(other_user)
        get :edit, params: route_params
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:alert]).to eq "You are not authorized to edit this note"
      end
    end

    # Test logic for authorized users
    context "when user is authorized" do
      let(:authorized_user) { owner } # Test with owner, 'editor_member' would also work

      before do
        allow(controller).to receive(:current_user).and_return(authorized_user)
      end

      it "renders the edit template" do
        get :edit, params: route_params
        expect(response).to render_template(:edit)
      end

      it "assigns a new note if one does not exist" do
        get :edit, params: route_params
        expect(assigns(:note)).to be_a_new(Note)
        expect(assigns(:note).user).to eq authorized_user
      end

      it "assigns the existing note if it exists" do
        existing_note = create(:note, lobby: lobby, user: owner)
        get :edit, params: route_params
        expect(assigns(:note)).to eq existing_note
      end
    end
  end

  describe "PATCH #update" do
    let(:valid_attributes) { { content: "This is the updated note." } }
    let(:invalid_attributes) { { content: "" } } # Assuming content cannot be blank

    # Combine route params and form data
    let(:valid_params) { route_params.merge(note: valid_attributes) }
    let(:invalid_params) { route_params.merge(note: invalid_attributes) }

    # Test authorization for 'update'
    context "when user is unauthorized" do
      it "redirects viewer_member" do
        allow(controller).to receive(:current_user).and_return(viewer_member)
        patch :update, params: valid_params
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:alert]).to eq "You are not authorized to edit this note"
      end

      it "redirects other_user (non-member)" do
        allow(controller).to receive(:current_user).and_return(other_user)
        patch :update, params: valid_params
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:alert]).to eq "You are not authorized to edit this note"
      end
    end

    # Test logic for authorized users (using 'editor_member' this time)
    context "when user is authorized (editor_member)" do
      before do
        allow(controller).to receive(:current_user).and_return(editor_member)
      end

      context "with valid parameters" do
        it "creates a new note if one doesn't exist" do
          expect {
            patch :update, params: valid_params
          }.to change(Note, :count).by(1)

          note = Note.last
          expect(note.content).to eq "This is the updated note."
          expect(note.lobby).to eq lobby
          expect(note.user).to eq editor_member # Note user is set to current_user
        end

        it "updates the existing note" do
          existing_note = create(:note, lobby: lobby, user: owner, content: "Old content")
          patch :update, params: valid_params

          existing_note.reload
          expect(existing_note.content).to eq "This is the updated note."
        end

        it "redirects to the lobby" do
          patch :update, params: valid_params
          expect(response).to redirect_to(lobby_path(lobby))
        end

        it "sets a success flash notice" do
          patch :update, params: valid_params
          expect(flash[:notice]).to eq "Note updated successfully"
        end
      end

      context "with invalid parameters" do
        it "does not save the note and re-renders :edit" do
          existing_note = create(:note, lobby: lobby, user: owner, content: "Old content")
          patch :update, params: invalid_params

          existing_note.reload
          expect(existing_note.content).to eq "Old content" # Unchanged
          expect(response).to render_template(:edit)
        end

        it "returns an :unprocessable_entity status" do
          patch :update, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end

