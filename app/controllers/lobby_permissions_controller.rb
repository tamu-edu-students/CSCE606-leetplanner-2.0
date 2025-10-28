class LobbyPermissionsController < ApplicationController
  before_action :authenticate_user!

  def update
    member = LobbyMember.find(params[:id])
    lobby = member.lobby

    # Authorization check: only lobby owner can update permissions
    unless current_user == lobby.owner
      return redirect_to lobby, alert: "You are not authorized to perform this action."
    end

    if member.update(permission_params)
      redirect_to lobby, notice: "#{member.user.name}'s permissions have been updated."
    else
      redirect_to lobby, alert: "Could not update permissions."
    end
  end

  private

  def permission_params
    params.require(:lobby_member).permit(:can_draw, :can_edit_notes, :can_speak)
  end
end
