require 'rails_helper'

RSpec.describe MessagesController, type: :controller do

  # --- Setup ---
  # Create a valid User (owner)
  let!(:owner) { User.create!(
    netid: "owner123",
    email: "owner@example.com",
    first_name: "Lobby",
    last_name: "Owner"
  ) }
  
  # Create a valid Lobby
  let!(:lobby) { Lobby.create!(
    name: "Test Lobby",
    owner: owner
  ) }
  
  # Create a valid User (the message sender)
  let!(:user) { User.create!(
    netid: "sender123",
    email: "sender@example.com",
    first_name: "Message",
    last_name: "Sender"
  ) }

  # --- Tests ---
  
  describe "POST #create" do
    
    # Define valid and invalid params
    let(:valid_params) { { lobby_id: lobby.id, message: { body: "This is a test message" } } }
    let(:invalid_params) { { lobby_id: lobby.id, message: { body: "" } } } # Assumes model validates body

    context "when user is authenticated" do
      before do
        # Sign in the user who will send the message
        session[:user_id] = user.id
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:authenticate_user!).and_return(true)
      end

      context "with valid parameters" do
        context "as HTML" do
          it "creates a new Message" do
            expect {
              post :create, params: valid_params
            }.to change(Message, :count).by(1)
          end

          it "redirects to the lobby with a notice" do
            post :create, params: valid_params
            expect(response).to redirect_to(lobby_path(lobby))
            expect(flash[:notice]).to eq("Message sent!")
          end

          it "assigns the message to the correct user and lobby" do
            post :create, params: valid_params
            message = Message.last
            expect(message.user).to eq(user)
            expect(message.lobby).to eq(lobby)
          end
        end

        context "as Turbo Stream" do
          it "creates a new Message" do
            expect {
              post :create, params: valid_params, as: :turbo_stream
            }.to change(Message, :count).by(1)
          end

          it "responds with a turbo_stream format" do
            post :create, params: valid_params, as: :turbo_stream
            expect(response.content_type).to eq("text/vnd.turbo-stream.html; charset=utf-8")
          end
        end
      end

      context "with invalid parameters" do
        # This context assumes your app/models/message.rb
        # has: validates :body, presence: true
        
        context "as HTML" do
          it "does not create a new Message" do
            expect {
              post :create, params: invalid_params
            }.not_to change(Message, :count)
          end

          it "redirects to the lobby with an alert" do
            post :create, params: invalid_params
            expect(response).to redirect_to(lobby_path(lobby))
            expect(flash[:alert]).to eq("Failed to send message.")
          end
        end

        context "as Turbo Stream" do
          it "does not create a new Message" do
            expect {
              post :create, params: invalid_params, as: :turbo_stream
            }.not_to change(Message, :count)
          end

          it "responds with a turbo_stream that replaces the form" do
            post :create, params: invalid_params, as: :turbo_stream
            expect(response.body).to include('turbo-stream action="replace" target="messages_form"')
          end
        end
      end
    end

    context "when user is not authenticated" do
      it "does not create a new Message" do
        expect {
          post :create, params: valid_params
        }.not_to change(Message, :count)
      end

      it "redirects to the sign-in page" do
        # Our app's authenticate_user! redirects unauthenticated users to root_path
        post :create, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You must be logged in to access this page.")
      end
    end
  end
end