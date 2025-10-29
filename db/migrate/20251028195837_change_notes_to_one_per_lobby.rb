class ChangeNotesToOnePerLobby < ActiveRecord::Migration[7.0]
  def change
    remove_index :notes, :lobby_id if index_exists?(:notes, :lobby_id)
    add_index :notes, :lobby_id, unique: true
  end
end
