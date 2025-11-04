class AddSessionsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions, if_not_exists: true do |t|
      t.string :session_id, null: false
      t.text :data
      t.timestamps
    end

    unless index_exists?(:sessions, :session_id, unique: true)
      add_index :sessions, :session_id, unique: true
    end
    unless index_exists?(:sessions, :updated_at)
      add_index :sessions, :updated_at
    end
  end
end
