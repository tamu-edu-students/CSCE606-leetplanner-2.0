require 'rails_helper'

RSpec.describe WhiteboardsController, type: :request do
  let(:user) { create(:user) }
  let(:lobby) { create(:lobby, owner: user) }
  let!(:whiteboard) { lobby.whiteboard }

  before do
    # Simulate login
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe 'POST /lobbies/:lobby_id/whiteboards/update_svg' do
    it 'updates svg_data when provided' do
      post update_svg_lobby_whiteboards_path(lobby), params: { svg_data: '<svg></svg>' }, as: :json
      expect(response).to have_http_status(:success)
      expect(whiteboard.reload.svg_data).to include('<svg')
    end

    it 'returns error when missing svg_data' do
      post update_svg_lobby_whiteboards_path(lobby), params: {}, as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'PATCH /lobbies/:lobby_id/whiteboards/update_notes' do
    it 'updates notes if permitted' do
      patch update_notes_lobby_whiteboards_path(lobby), params: { whiteboard: { notes: 'New notes' } }
      expect(response).to redirect_to(lobby_path(lobby))
      expect(whiteboard.reload.notes).to eq('New notes')
    end
  end
end
