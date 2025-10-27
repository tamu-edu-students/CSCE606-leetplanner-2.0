class RemoveMembersFromLobbies < ActiveRecord::Migration[8.0]
  def change
    remove_column :lobbies, :members, :text
  end
end
