class CreateLobbies < ActiveRecord::Migration[8.0]
  def change
    create_table :lobbies do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.text :description
      t.text :members
      t.string :lobby_code, null: false

      t.timestamps
    end
    add_index :lobbies, :lobby_code, unique: true
  end
end
