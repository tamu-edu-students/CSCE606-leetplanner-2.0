class LobbyParticipationsController < ApplicationController
  before_action :authenticate_user!
  def create_by_code
    lobby = Lobby.find_by(invite_code: params[:invite_code])

    if lobby
      @participation = lobby.lobby_participations.build(user: current_user)
      if @participation.save
        # Broadcast that a user has joined (for real-time updates)
        LobbyChannel.broadcast_to(lobby, { type: 'USER_JOINED', user: current_user.slice(:id, :name) })
        redirect_to lobby, notice: "Successfully joined the lobby!"
      else
        redirect_to root_path, alert: "You are already in this lobby."
      end
    else
      redirect_to root_path, alert: "Invalid invite code. Please try again."
    end
  end
  
end