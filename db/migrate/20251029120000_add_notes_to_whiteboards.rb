class AddNotesToWhiteboards < ActiveRecord::Migration[8.0]
  def change
    add_column :whiteboards, :notes, :text
  end
end
