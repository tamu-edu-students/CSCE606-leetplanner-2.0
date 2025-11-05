class CreateNotesForce < ActiveRecord::Migration[8.0]
  def up
    return if table_exists?(:notes)
    execute 'CREATE TABLE notes (id bigserial PRIMARY KEY, content text DEFAULT \'\', lobby_id bigint NOT NULL, user_id bigint NOT NULL, created_at timestamp NOT NULL, updated_at timestamp NOT NULL)'
    add_foreign_key :notes, :lobbies
    add_foreign_key :notes, :users
    add_index :notes, :lobby_id, unique: true
  end

  def down
    drop_table :notes if table_exists?(:notes)
  end
end
