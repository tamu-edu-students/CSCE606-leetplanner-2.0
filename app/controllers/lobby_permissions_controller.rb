class LobbyPermissionsController < ApplicationController
  before_action :authenticate_user!

  def update
    participation = LobbyParticipation.find(params[:id])
    lobby = participation.lobby

    # Authorization: Only the host can change permissions
    unless current_user == lobby.host
      return redirect_to lobby, alert: "You are not authorized to perform this action."
    end

    if participation.update(permission_params)
      redirect_to lobby, notice: "#{participation.user.name}'s permissions have been updated."
    else
      redirect_to lobby, alert: "Could not update permissions."
    end
  end

  private

  def permission_params
    params.require(:lobby_participation).permit(:can_draw, :can_edit_notes, :can_speak)
  end
end