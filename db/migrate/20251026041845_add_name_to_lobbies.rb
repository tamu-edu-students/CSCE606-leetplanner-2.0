class AddNameToLobbies < ActiveRecord::Migration[8.0]
  def change
    add_column :lobbies, :name, :string
  end
end
