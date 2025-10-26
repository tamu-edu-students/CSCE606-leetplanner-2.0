class CreateLobbyMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :lobby_members do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lobby, null: false, foreign_key: true

      t.timestamps
    end
  end
end
