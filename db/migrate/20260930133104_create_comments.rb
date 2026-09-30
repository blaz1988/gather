class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      # The [event_id, created_at] index already leads with event_id.
      t.references :event, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps

      t.index [ :event_id, :created_at ]
      t.check_constraint "length(trim(body)) > 0 AND length(body) <= 1000", name: "comments_body_length_check"
    end
  end
end
