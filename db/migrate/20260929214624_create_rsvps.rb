class CreateRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :rsvps do |t|
      # The unique [event_id, user_id] index already leads with event_id.
      t.references :event, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false

      t.timestamps

      t.index [ :event_id, :user_id ], unique: true
      t.index [ :event_id, :status, :created_at ]
      t.check_constraint "status IN ('going', 'waitlisted')", name: "rsvps_status_check"
    end
  end
end
