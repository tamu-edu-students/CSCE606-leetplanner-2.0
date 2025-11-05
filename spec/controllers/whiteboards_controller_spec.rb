require 'rails_helper'

RSpec.describe WhiteboardsController, type: :controller do
  let(:user) { create(:user) }
  let(:lobby) { create(:lobby, owner: user) }
  let(:whiteboard) { create(:whiteboard, lobby: lobby) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:user_signed_in?).and_return(true)
  end

  describe 'GET #show' do
    it 'returns JSON with svg_data and notes for collection route' do
      get :show, params: { lobby_id: lobby.id }, format: :json
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('svg_data')
      expect(json_response).to have_key('notes')
    end

    it 'returns JSON with svg_data and notes for individual route' do
      get :show, params: { lobby_id: lobby.id }, format: :json
      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('svg_data')
      expect(json_response).to have_key('notes')
    end
  end

  describe 'POST #add_drawing' do
    context 'when adding a rectangle' do
      it 'adds rectangle to whiteboard and redirects' do
        post :add_drawing, params: {
          lobby_id: lobby.id,
          tool: 'rectangle',
          x: 10, y: 20, width: 50, height: 30,
          color: '#ff0000'
        }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:notice]).to eq('Added rectangle to whiteboard!')
      end
    end

    context 'when adding a circle' do
      it 'adds circle to whiteboard and redirects' do
        post :add_drawing, params: {
          lobby_id: lobby.id,
          tool: 'circle',
          x: 100, y: 100, radius: 25,
          color: '#00ff00'
        }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:notice]).to eq('Added circle to whiteboard!')
      end
    end

    context 'when adding text' do
      it 'adds text to whiteboard and redirects' do
        post :add_drawing, params: {
          lobby_id: lobby.id,
          tool: 'text',
          x: 50, y: 75, text: 'Hello World',
          color: '#0000ff'
        }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:notice]).to eq('Added text to whiteboard!')
      end
    end

    context 'when adding a line' do
      it 'adds line to whiteboard and redirects' do
        post :add_drawing, params: {
          lobby_id: lobby.id,
          tool: 'line',
          x1: 0, y1: 0, x2: 100, y2: 100,
          color: '#ff00ff', width: '3'
        }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:notice]).to eq('Added line to whiteboard!')
      end
    end

    context 'when using default colors and widths' do
      it 'uses default values when not provided' do
        post :add_drawing, params: {
          lobby_id: lobby.id,
          tool: 'rectangle',
          x: 10, y: 20, width: 50, height: 30
        }
        expect(response).to redirect_to(lobby_path(lobby))
        lobby.whiteboard.reload
        expect(lobby.whiteboard.svg_data).to include('#000000')
      end
    end
  end

  describe 'POST #clear' do
    it 'clears the whiteboard and redirects' do
      post :clear, params: { lobby_id: lobby.id }
      expect(response).to redirect_to(lobby_path(lobby))
      expect(flash[:notice]).to eq('Whiteboard cleared!')
    end

    it 'resets svg_data to default' do
      original_data = lobby.whiteboard.svg_data
      post :clear, params: { lobby_id: lobby.id }
      lobby.whiteboard.reload
      expect(lobby.whiteboard.svg_data).not_to eq(original_data)
      expect(lobby.whiteboard.svg_data).to include('viewBox="0 0 800 350"')
    end
  end

  describe 'POST #update_svg' do
    context 'with valid svg_data' do
      it 'updates the whiteboard svg_data' do
        svg_data = '<svg><rect x="10" y="10" width="50" height="50"/></svg>'
        post :update_svg, params: { lobby_id: lobby.id, svg_data: svg_data }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        lobby.whiteboard.reload
        expect(lobby.whiteboard.svg_data).to eq(svg_data)
      end
    end

    context 'without svg_data' do
      it 'returns error status' do
        post :update_svg, params: { lobby_id: lobby.id }
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('No SVG data provided')
      end
    end
  end

  describe 'PATCH #update_notes' do
    context 'when user is lobby owner' do
      it 'updates notes and redirects with success message' do
        patch :update_notes, params: {
          lobby_id: lobby.id,
          whiteboard: { notes: 'Updated notes content' }
        }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:notice]).to eq('Notes updated.')
        lobby.whiteboard.reload
        expect(lobby.whiteboard.notes).to eq('Updated notes content')
      end
    end

    context 'when user is not owner but has permission' do
      let(:member) { create(:user) }
      let!(:lobby_member) { create(:lobby_member, lobby: lobby, user: member, can_edit_notes: true) }

      before do
        allow(controller).to receive(:current_user).and_return(member)
      end

      it 'allows updating notes' do
        patch :update_notes, params: {
          lobby_id: lobby.id,
          whiteboard: { notes: 'Member updated notes' }
        }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:notice]).to eq('Notes updated.')
      end
    end

    context 'when user lacks permission' do
      let(:unauthorized_user) { create(:user) }
      let!(:lobby_member) { create(:lobby_member, lobby: lobby, user: unauthorized_user, can_edit_notes: false) }

      before do
        allow(controller).to receive(:current_user).and_return(unauthorized_user)
      end

      it 'denies access and redirects with error' do
        patch :update_notes, params: {
          lobby_id: lobby.id,
          whiteboard: { notes: 'Unauthorized update' }
        }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:alert]).to eq('Not authorized to edit notes.')
      end
    end

    context 'without whiteboard params' do
      it 'denies access' do
        patch :update_notes, params: { lobby_id: lobby.id }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:alert]).to eq('Not authorized to edit notes.')
      end
    end

    context 'when update fails' do
      before do
        allow_any_instance_of(Whiteboard).to receive(:update).and_return(false)
      end

      it 'redirects with error message' do
        patch :update_notes, params: {
          lobby_id: lobby.id,
          whiteboard: { notes: 'Failed update' }
        }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:alert]).to eq('Failed to update notes.')
      end
    end
  end

  describe 'private methods' do
    describe '#set_lobby' do
      it 'sets @lobby instance variable' do
        get :show, params: { lobby_id: lobby.id }, format: :json
        expect(assigns(:lobby)).to eq(lobby)
      end
    end

    describe '#set_whiteboard' do
      context 'when whiteboard exists' do
        it 'sets existing whiteboard' do
          get :show, params: { lobby_id: lobby.id }, format: :json
          expect(assigns(:whiteboard)).to eq(lobby.whiteboard)
        end
      end

      context 'when whiteboard does not exist' do
        let(:lobby_without_whiteboard) { create(:lobby, owner: user) }

        before do
          lobby_without_whiteboard.whiteboard&.destroy
        end

        it 'creates new whiteboard' do
          expect do
            get :show, params: { lobby_id: lobby_without_whiteboard.id }, format: :json
          end.to change(Whiteboard, :count).by(1)
        end
      end
    end

    describe '#permitted_to_edit_notes?' do
      context 'when user is lobby owner' do
        it 'returns true' do
          get :show, params: { lobby_id: lobby.id }, format: :json
          expect(controller.send(:permitted_to_edit_notes?)).to be_truthy
        end
      end

      context 'when user is member with permission' do
        let(:member) { create(:user) }
        let!(:lobby_member) { create(:lobby_member, lobby: lobby, user: member, can_edit_notes: true) }

        before do
          allow(controller).to receive(:current_user).and_return(member)
        end

        it 'returns true' do
          get :show, params: { lobby_id: lobby.id }, format: :json
          expect(controller.send(:permitted_to_edit_notes?)).to be_truthy
        end
      end

      context 'when user lacks permission' do
        let(:unauthorized_user) { create(:user) }
        let!(:lobby_member) { create(:lobby_member, lobby: lobby, user: unauthorized_user, can_edit_notes: false) }

        before do
          allow(controller).to receive(:current_user).and_return(unauthorized_user)
        end

        it 'returns false' do
          get :show, params: { lobby_id: lobby.id }, format: :json
          expect(controller.send(:permitted_to_edit_notes?)).to be_falsy
        end
      end
    end

    describe '#create_default_svg' do
      it 'creates svg with grid pattern' do
        get :show, params: { lobby_id: lobby.id }, format: :json
        default_svg = controller.send(:create_default_svg)
        expect(default_svg).to include('viewBox="0 0 800 350"')
        expect(default_svg).to include('pattern id="grid"')
        expect(default_svg).to include('class="whiteboard-svg"')
      end
    end

    describe 'SVG manipulation methods' do
      let(:base_svg) { controller.send(:create_default_svg) }

      describe '#add_rectangle_to_svg' do
        it 'adds rectangle element to svg' do
          result = controller.send(:add_rectangle_to_svg, base_svg, 10, 20, 50, 30, '#ff0000')
          expect(result).to include('<rect x="10" y="20" width="50" height="30"')
          expect(result).to include('stroke="#ff0000"')
        end
      end

      describe '#add_circle_to_svg' do
        it 'adds circle element to svg' do
          result = controller.send(:add_circle_to_svg, base_svg, 100, 100, 25, '#00ff00')
          expect(result).to include('<circle cx="100" cy="100" r="25"')
          expect(result).to include('stroke="#00ff00"')
        end
      end

      describe '#add_text_to_svg' do
        it 'adds text element to svg' do
          result = controller.send(:add_text_to_svg, base_svg, 50, 75, 'Hello World', '#0000ff')
          expect(result).to include('<text x="50" y="75"')
          expect(result).to include('fill="#0000ff"')
          expect(result).to include('Hello World')
        end
      end

      describe '#add_line_to_svg' do
        it 'adds line element to svg' do
          result = controller.send(:add_line_to_svg, base_svg, 0, 0, 100, 100, '#ff00ff', '3')
          expect(result).to include('<line x1="0" y1="0" x2="100" y2="100"')
          expect(result).to include('stroke="#ff00ff"')
          expect(result).to include('stroke-width="3"')
        end
      end
    end
  end

  describe 'controller inheritance' do
    it 'inherits from ApplicationController' do
      expect(WhiteboardsController.superclass).to eq(ApplicationController)
    end
  end
end
