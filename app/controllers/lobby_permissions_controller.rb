class LobbyPermissionsController < ApplicationController
  before_action :authenticate_user!

  def update
    puts "--- PERMISSIONS UPDATE ACTION REACHED ---"
    puts "--- PARAMS RECEIVED: #{params.inspect} ---"
    member = LobbyMember.find(params[:id])
    lobby = member.lobby

    # Authorization check: only lobby owner can update permissions
    unless current_user == lobby.owner
      return redirect_to lobby, alert: "You are not authorized to perform this action."
    end

    if member.update(permission_params)
      redirect_to lobby, notice: "#{member.user.full_name}'s permissions have been updated."
    else
      redirect_to lobby, alert: "Could not update permissions."
    end
  end

  def update_all
    @lobby = Lobby.find(params[:id])

    # Authorization: Ensure the current user is the owner
    unless current_user == @lobby.owner
      return redirect_to @lobby, alert: "You are not authorized to perform this action."
    end

    if @lobby.update(lobby_permissions_params)
      redirect_to @lobby, notice: "All participant permissions have been updated."
    else
      redirect_to @lobby, alert: "Could not update permissions."
    end
  end

  private

  def lobby_permissions_params
    params.require(:lobby).permit(
      lobby_members_attributes: [ :id, :can_draw, :can_edit_notes ]
    )
  end

  def permission_params
    params.require(:lobby_member).permit(:can_draw, :can_edit_notes, :can_speak)
        .with_defaults(can_draw: false, can_edit_notes: false, can_speak: false)
  end
end
