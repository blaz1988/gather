class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.string :venue, null: false
      t.integer :capacity, null: false
      t.references :organizer, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :events, :starts_at
  end
end
