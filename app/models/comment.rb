class Comment < ApplicationRecord
  MAX_LENGTH = 1_000

  belongs_to :event
  belongs_to :user

  validates :body, presence: true, length: { maximum: MAX_LENGTH }

  normalizes :body, with: ->(body) { body.strip }

  scope :oldest_first, -> { order(:created_at, :id) }

  def deletable_by?(user) = user.present? && user_id == user.id
end
