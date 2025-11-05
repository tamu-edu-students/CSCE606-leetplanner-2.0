require 'rails_helper'

RSpec.describe "Messages", type: :request do
  let(:lobby) { create(:lobby) }
  let(:user) { lobby.owner }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe 'POST /lobbies/:lobby_id/messages' do
    it 'creates a message and redirects (HTML)' do
      post lobby_messages_path(lobby), params: { message: { body: 'Hello world' } }
      expect(response).to redirect_to(lobby_path(lobby))
      follow_redirect!
      expect(response.body).to include('Hello world')
    end

    it 'does not create invalid message' do
      expect {
        post lobby_messages_path(lobby), params: { message: { body: '' } }
      }.not_to change(Message, :count)
      expect(response).to redirect_to(lobby_path(lobby))
    end
  end
end
