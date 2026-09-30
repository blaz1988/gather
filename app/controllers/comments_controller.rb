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

  def destroy
    comment = @event.comments.find(params[:id])
    return redirect_to event_path(@event), alert: "You can't delete this comment." unless comment.deletable_by?(Current.user)

    comment.destroy!
    Rails.logger.info("Comment deleted: comment_id=#{comment.id} event_id=#{comment.event_id} " \
      "author_id=#{comment.user_id} deleted_by=#{Current.user.id}")
    redirect_to event_path(@event, anchor: "comments"), notice: "Comment deleted."
  end

  private
    def set_event
      @event = Event.find(params[:event_id])
    end

    def comment_params
      params.expect(comment: [ :body ])
    end
end
