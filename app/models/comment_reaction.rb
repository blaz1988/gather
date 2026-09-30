class CommentReaction < ApplicationRecord
  belongs_to :comment
  belongs_to :user

  enum :kind, %w[ like dislike ].index_by(&:itself), validate: true

  validates :user_id, uniqueness: { scope: :comment_id }
end
