class EventsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :resume_session, only: %i[ index show ]
  before_action :set_event, only: %i[ show edit update ]
  before_action :require_organizer, only: %i[ edit update ]

  def index
    @events = Event.upcoming.includes(:organizer)
    @going_counts = Rsvp.going.where(event: @events).group(:event_id).count
  end

  def show
    @rsvp = @event.rsvp_for(Current.user)
    @rsvps = @event.rsvps.includes(:user).in_line_order if @event.organized_by?(Current.user)
    @comments = @event.comments.oldest_first.includes(:user).load
  end

  def new
    @event = Event.new(starts_at: 1.week.from_now.change(hour: 18), capacity: 30)
  end

  def create
    @event = Current.user.organized_events.build(event_params)
    if @event.save
      redirect_to @event, notice: "Event created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Event updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_event
      @event = Event.find(params[:id])
    end

    def require_organizer
      redirect_to @event, alert: "Only the organizer can change this event." unless @event.organized_by?(Current.user)
    end

    def event_params
      params.expect(event: %i[ title description starts_at venue capacity ])
    end
end
