class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.text :content, default: ""
      # Avoid automatic index so we can create a UNIQUE index explicitly afterward
      t.references :lobby, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    # Ensure unique index, handling case where a non-unique index was auto-created in previous attempts
    unless index_exists?(:notes, :lobby_id, unique: true)
      remove_index :notes, :lobby_id if index_exists?(:notes, :lobby_id)
      add_index :notes, :lobby_id, unique: true
    end
  end
end
