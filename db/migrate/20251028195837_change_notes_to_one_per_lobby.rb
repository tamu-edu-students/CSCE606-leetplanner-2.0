class ChangeNotesToOnePerLobby < ActiveRecord::Migration[7.0]
  def change
    # This migration originally enforced uniqueness; guard so it is idempotent.
    unless index_exists?(:notes, :lobby_id, unique: true)
      remove_index :notes, :lobby_id if index_exists?(:notes, :lobby_id)
      add_index :notes, :lobby_id, unique: true
    end
  end
end
