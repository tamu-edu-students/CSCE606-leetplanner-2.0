class AddPrivateToLobbies < ActiveRecord::Migration[8.0]
  def change
    add_column :lobbies, :private, :boolean, default: false
    add_index :lobbies, :private
  end
end
