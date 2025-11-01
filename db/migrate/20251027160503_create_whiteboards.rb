class CreateWhiteboards < ActiveRecord::Migration[8.0]
  def change
    create_table :whiteboards do |t|
      t.references :lobby, null: false, foreign_key: true
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
