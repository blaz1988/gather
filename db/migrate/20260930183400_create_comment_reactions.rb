class CreateCommentReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :comment_reactions do |t|
      # The [comment_id, user_id] index already leads with comment_id.
      # Both foreign keys cascade because Event and User delete comments with delete_all, which skips callbacks.
      t.references :comment, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false

      t.timestamps

      t.index %i[ comment_id user_id ], unique: true
      t.check_constraint "kind IN ('like', 'dislike')", name: "comment_reactions_kind_check"
    end
  end
end
