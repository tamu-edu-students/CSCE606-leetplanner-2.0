class LobbyMembersController < ApplicationController
  before_action :authenticate_user!

  def create_by_code
    lobby = Lobby.find_by(lobby_code: params[:lobby_code]&.upcase)

    if lobby
      @member = lobby.lobby_members.build(user: current_user)
      if @member.save
        redirect_to lobby, notice: "Successfully joined the lobby!"
      else
        redirect_to root_path, alert: "You are already in this lobby."
      end
    else
      redirect_to root_path, alert: "Invalid lobby code. Please try again."
    end
  end

  def destroy
    lobby = Lobby.find(params[:id])
    # Find the LobbyMember record for the current user
    member = lobby.lobby_members.find_by(user: current_user)

    if member&.destroy
      redirect_to root_path, notice: "You have left the lobby."
    else
      redirect_to root_path, alert: "You were not in that lobby."
    end
  end
end
