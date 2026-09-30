class Event < ApplicationRecord
  belongs_to :organizer, class_name: "User"
  has_many :rsvps, dependent: :delete_all
  has_many :comments, dependent: :delete_all, inverse_of: :event
  has_many :attendees, -> { merge(Rsvp.going) }, through: :rsvps, source: :user

  validates :title, :starts_at, :venue, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }

  scope :upcoming, -> { where(starts_at: Time.current..).order(:starts_at) }

  def organized_by?(user)
    user.present? && organizer_id == user.id
  end

  def seats_taken
    @seats_taken ||= rsvps.going.count
  end

  def seats_left(taken = seats_taken)
    [ capacity - taken, 0 ].max
  end

  def full?
    seats_left.zero?
  end

  def waitlist_count
    rsvps.waitlisted.count
  end

  def rsvps_open?
    starts_at.future?
  end

  def rsvp_for(user)
    rsvps.find_by(user:) if user
  end

  def rsvp(user)
    return if user.nil? || organized_by?(user) || !rsvps_open?

    transaction do
      lock!
      rsvps.find_by(user:) || rsvps.create!(user:, status: full? ? :waitlisted : :going)
    end
  rescue ActiveRecord::RecordNotUnique
    rsvps.find_by(user:)
  ensure
    @seats_taken = nil
  end

  def reload(*)
    @seats_taken = nil
    super
  end
end
