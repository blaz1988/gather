class CommentsController < ApplicationController
  before_action :set_event

  def create
    @comment = @event.comments.new(comment_params.merge(user: Current.user))

    if @comment.save
      redirect_to event_path(@event, anchor: "comments"), notice: "Comment posted."
    else
      redirect_to event_path(@event, anchor: "comments"), alert: @comment.errors.full_messages.to_sentence
    end
  end

  private
    def set_event
      @event = Event.find(params[:event_id])
    end

    def comment_params
      params.expect(comment: [ :body ])
    end
end
