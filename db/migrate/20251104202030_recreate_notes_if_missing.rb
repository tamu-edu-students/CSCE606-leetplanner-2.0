class RecreateNotesIfMissing < ActiveRecord::Migration[8.0]
  def up
    return if table_exists?(:notes)
    create_table :notes do |t|
      t.text :content, default: ""
      t.references :lobby, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :notes, :lobby_id, unique: true
  end

  def down
    drop_table :notes if table_exists?(:notes)
  end
end
