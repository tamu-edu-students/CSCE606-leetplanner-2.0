class AddPermissionsToLobbyMembers < ActiveRecord::Migration[7.0]
  def change
    add_column :lobby_members, :can_draw, :boolean, default: false
    add_column :lobby_members, :can_edit_notes, :boolean, default: false
    add_column :lobby_members, :can_speak, :boolean, default: false
  end
end
