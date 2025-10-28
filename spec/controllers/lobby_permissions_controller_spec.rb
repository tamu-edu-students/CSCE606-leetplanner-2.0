require 'rails_helper'

RSpec.describe LobbyPermissionsController, type: :controller do
  let(:owner) { create(:user) }
  let(:participant) { create(:user) }
  let(:lobby) { create(:lobby, owner: owner) }
  let!(:member) { create(:lobby_member, lobby: lobby, user: participant) }

  describe 'PATCH #update' do
    context 'when logged in as the lobby owner' do
      before do
        allow(controller).to receive(:current_user).and_return(owner)
      end

      it 'updates the member permissions successfully' do
        patch :update, params: {
          id: member.id,
          lobby_member: { can_draw: true, can_edit_notes: false }
        }
        member.reload
        expect(member.can_draw).to be(true)
        expect(member.can_edit_notes).to be(false)
      end

      it 'redirects to the lobby with a success notice' do
        patch :update, params: { id: member.id, lobby_member: { can_draw: true } }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:notice]).to include("#{participant.full_name}'s permissions have been updated.")
      end
    end

    context 'when logged in as a non-owner' do
      before do
        allow(controller).to receive(:current_user).and_return(participant)
      end

      it 'does not update the member permissions' do
        expect {
          patch :update, params: { id: member.id, lobby_member: { can_draw: true } }
        }.not_to change { member.reload.can_draw }
      end

      it 'redirects to the lobby with an authorization alert' do
        patch :update, params: { id: member.id, lobby_member: { can_draw: true } }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:alert]).to eq('You are not authorized to perform this action.')
      end
    end

    context 'when the update fails' do
      before do
        allow(controller).to receive(:current_user).and_return(owner)
        # Force the update method to return false
        allow_any_instance_of(LobbyMember).to receive(:update).and_return(false)
      end

      it 'redirects to the lobby with an alert' do
        patch :update, params: { id: member.id, lobby_member: { can_draw: true } }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:alert]).to eq('Could not update permissions.')
      end
    end
  end

  describe 'PATCH #update_all' do
    let(:participant2) { create(:user) }
    let!(:member2) { create(:lobby_member, lobby: lobby, user: participant2, can_draw: true) }

    context 'when logged in as the lobby owner' do
      before do
        allow(controller).to receive(:current_user).and_return(owner)
      end

      it 'updates all member permissions from the form' do
        patch :update_all, params: {
          id: lobby.id,
          lobby: {
            lobby_members_attributes: {
              '0' => { id: member.id, can_draw: '1' }, # Granting draw permission to participant 1
              '1' => { id: member2.id, can_draw: '0' } # Revoking draw permission from participant 2
            }
          }
        }
        expect(member.reload.can_draw).to be(true)
        expect(member2.reload.can_draw).to be(false)
      end

      it 'redirects to the lobby with a success notice' do
        patch :update_all, params: {
          id: lobby.id,
          lobby: { lobby_members_attributes: { '0' => { id: member.id, can_draw: '1' } } }
        }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:notice]).to eq('All participant permissions have been updated.')
      end
    end

    context 'when logged in as a non-owner' do
      before do
        allow(controller).to receive(:current_user).and_return(participant)
      end

      it 'does not update any permissions' do
        expect {
          patch :update_all, params: {
            id: lobby.id,
            lobby: { lobby_members_attributes: { '0' => { id: member2.id, can_draw: '0' } } }
          }
        }.not_to change { member2.reload.can_draw }
      end

      it 'redirects to the lobby with an authorization alert' do
        patch :update_all, params: {
          id: lobby.id,
          lobby: { lobby_members_attributes: { '0' => { id: member2.id, can_draw: '0' } } }
        }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:alert]).to eq('You are not authorized to perform this action.')
      end
    end

    context 'when the update fails' do
      before do
        allow(controller).to receive(:current_user).and_return(owner)
        # Force the lobby's update method to return false
        allow_any_instance_of(Lobby).to receive(:update).and_return(false)
      end

      it 'redirects to the lobby with an alert' do
        patch :update_all, params: {
          id: lobby.id,
          lobby: { lobby_members_attributes: { '0' => { id: member.id, can_draw: '1' } } }
        }
        expect(response).to redirect_to(lobby_path(lobby))
        expect(flash[:alert]).to eq('Could not update permissions.')
      end
    end
  end
end
