class LobbyParticipationsController < ApplicationController
  before_action :authenticate_user!
  def create_by_code
    lobby = Lobby.find_by(invite_code: params[:invite_code]&.upcase)

    if lobby
      @participation = lobby.lobby_participations.build(user: current_user)
      if @participation.save
        redirect_to lobby, notice: "Successfully joined the lobby!"
      else
        # This handles the case where the user is already in the lobby
        redirect_to root_path, alert: "You are already in this lobby."
      end
    else
      redirect_to root_path, alert: "Invalid invite code. Please try again."
    end
  end

  def destroy
    # find the lobby via its id from the URL params
    lobby = Lobby.find(params[:id])
    participation = lobby.lobby_participations.find_by(user: current_user)

    if participation&.destroy
      redirect_to root_path, notice: "You have left the lobby."
    else
      redirect_to root_path, alert: "You were not in that lobby."
    end
  end
  
end