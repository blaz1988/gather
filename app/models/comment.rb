class Comment < ApplicationRecord
  MAX_LENGTH = 1_000

  belongs_to :event
  belongs_to :user
  has_many :reactions, class_name: "CommentReaction", dependent: :delete_all

  validates :body, presence: true, length: { maximum: MAX_LENGTH }

  normalizes :body, with: ->(body) { body.strip }

  scope :oldest_first, -> { order(:created_at, :id) }

  def self.reaction_counts_for(comments)
    counts = Hash.new { |hash, comment_id| hash[comment_id] = CommentReaction.kinds.keys.index_with(0) }
    CommentReaction.where(comment: comments.to_a).group(:comment_id, :kind).count.each do |(comment_id, kind), count|
      counts[comment_id][kind] = count
    end
    counts
  end

  def deletable_by?(user) = user.present? && (user_id == user.id || event.organized_by?(user))
end
