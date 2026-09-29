class RsvpsController < ApplicationController
  before_action :set_event

  def create
    if rsvp = @event.rsvp(Current.user)
      redirect_to @event, notice: rsvp.going? ? "You're going." : "You're ##{rsvp.waitlist_position} on the waitlist."
    else
      redirect_to @event
    end
  end

  def destroy
    return redirect_to(@event) unless @event.rsvps_open?

    Current.user.rsvps.find_by(event: @event)&.destroy
    redirect_to @event, notice: "Your RSVP was cancelled."
  end

  private
    def set_event
      @event = Event.find(params[:event_id])
    end
end
