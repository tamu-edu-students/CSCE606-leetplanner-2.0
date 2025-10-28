class CreateLobbyParticipations < ActiveRecord::Migration[7.0]
  def change
    create_table :lobby_participations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lobby, null: false, foreign_key: true
      t.boolean :can_draw, default: false
      t.boolean :can_edit_notes, default: false
      t.boolean :can_speak, default: false

      t.timestamps
    end
    # a unique index to prevent a user from joining the same lobby twice
    add_index :lobby_participations, [:user_id, :lobby_id], unique: true
  end
end