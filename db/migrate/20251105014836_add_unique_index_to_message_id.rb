class AddUniqueIndexToMessageId < ActiveRecord::Migration[7.0] # Use your Rails version
  def change
    unless index_exists?(:messages, :id, unique: true)
      add_index :messages, :id, unique: true
    end
  end
end
