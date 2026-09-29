class Rsvp < ApplicationRecord
  belongs_to :event
  belongs_to :user

  enum :status, %w[ going waitlisted ].index_by(&:itself), validate: true

  validates :user_id, uniqueness: { scope: :event_id }

  scope :in_line_order, -> { order(:created_at, :id) }

  after_destroy :promote_next_waitlisted, if: :going?

  def waitlist_position
    return unless waitlisted?

    event.rsvps.waitlisted
      .where("created_at < ? OR (created_at = ? AND id < ?)", created_at, created_at, id)
      .count + 1
  end

  private
    def promote_next_waitlisted
      event.rsvps.waitlisted.in_line_order.first&.tap do
        it.going!
        Rails.logger.info("Promoted RSVP from waitlist: event_id=#{event_id} user_id=#{it.user_id}")
      end
    end
end
