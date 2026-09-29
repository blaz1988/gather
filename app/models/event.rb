class Event < ApplicationRecord
  belongs_to :organizer, class_name: "User"

  validates :title, :starts_at, :venue, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }

  scope :upcoming, -> { where(starts_at: Time.current..).order(:starts_at) }

  def organized_by?(user)
    user.present? && organizer_id == user.id
  end
end
