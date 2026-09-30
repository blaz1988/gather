require "rails_helper"

RSpec.describe "Comments", type: :request do
  let(:organizer) { create(:user, name: "Ana Kovač") }
  let(:event) { create(:event, organizer: organizer) }
  let(:marko) { create(:user, name: "Marko Horvat") }

  context "as a guest" do
    it "redirects POST to sign-in and creates nothing" do
      expect { post event_comments_path(event), params: { comment: { body: "Is there parking nearby?" } } }
        .not_to change(Comment, :count)
      expect(response).to redirect_to(new_session_path)
    end

    it "shows a sign-in link instead of the comment form" do
      get event_path(event)

      expect(response.body).to include("Sign in to comment")
      expect(response.body).not_to include('id="new-comment"')
    end
  end

  context "when signed in" do
    before { sign_in marko }

    it "shows the comment form with a required, length-limited textarea" do
      get event_path(event)

      textarea = Nokogiri::HTML(response.body).at_css("form#new-comment textarea[name='comment[body]']")
      expect(textarea).to be_present
      expect(textarea["required"]).to be_present
      expect(textarea["maxlength"]).to eq("1000")
      expect(response.body).not_to include("Sign in to comment")
    end

    it "creates a comment by the current person and redirects to the comments" do
      expect { post event_comments_path(event), params: { comment: { body: "Is there parking nearby?" } } }
        .to change(Comment, :count).by(1)

      expect(event.comments.sole).to have_attributes(user: marko, body: "Is there parking nearby?")
      expect(response).to redirect_to(event_path(event, anchor: "comments"))
      expect(flash[:notice]).to eq("Comment posted.")
    end

    [ "", "   \n\t" ].each do |body|
      it "creates nothing and alerts for the body #{body.inspect}" do
        expect { post event_comments_path(event), params: { comment: { body: body } } }.not_to change(Comment, :count)

        expect(response).to redirect_to(event_path(event, anchor: "comments"))
        expect(flash[:alert]).to eq("Body can't be blank")
      end
    end

    it "creates nothing and alerts when the body is too long" do
      body = "a" * (Comment::MAX_LENGTH + 1)
      expect { post event_comments_path(event), params: { comment: { body: body } } }.not_to change(Comment, :count)

      expect(response).to redirect_to(event_path(event, anchor: "comments"))
      expect(flash[:alert]).to eq("Body is too long (maximum is 1000 characters)")
    end

    it "ignores user_id, event_id and created_at params" do
      other_event = create(:event, organizer: organizer)
      forged = { user_id: organizer.id, event_id: other_event.id, created_at: "2020-01-01 00:00" }

      post event_comments_path(event), params: forged.merge(comment: forged.merge(body: "Is there parking nearby?"))

      expect(Comment.sole).to have_attributes(user_id: marko.id, event_id: event.id,
        created_at: be_within(1.minute).of(Time.current))
    end

    it "returns 404 for an unknown event" do
      post event_comments_path(event_id: 0), params: { comment: { body: "Is there parking nearby?" } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /events/:event_id/comments/:id" do
    let!(:comment) { create(:comment, event: event, user: marko) }

    it "redirects a guest to sign-in and deletes nothing" do
      expect { delete event_comment_path(event, comment) }.not_to change(Comment, :count)
      expect(response).to redirect_to(new_session_path)
    end

    it "lets the author delete their comment and logs it" do
      sign_in marko
      allow(Rails.logger).to receive(:info).and_call_original

      expect { delete event_comment_path(event, comment) }.to change(Comment, :count).by(-1)

      expect(response).to redirect_to(event_path(event, anchor: "comments"))
      expect(flash[:notice]).to eq("Comment deleted.")
      expect(Rails.logger).to have_received(:info).with(
        "Comment deleted: comment_id=#{comment.id} event_id=#{event.id} author_id=#{marko.id} deleted_by=#{marko.id}"
      )
    end

    it "refuses another user and keeps the comment" do
      sign_in create(:user)

      expect { delete event_comment_path(event, comment) }.not_to change(Comment, :count)

      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to eq("You can't delete this comment.")
    end

    it "returns 404 for a comment id through another event's URL" do
      sign_in marko
      other_event = create(:event)

      expect { delete event_comment_path(other_event, comment) }.not_to change(Comment, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Delete button on the event page" do
    let!(:own) { create(:comment, event: event, user: marko, body: "Mine") }
    let!(:other) { create(:comment, event: event, body: "Theirs") }

    def delete_forms
      Nokogiri::HTML(response.body).css("form[action^='#{event_comments_path(event)}/']")
    end

    it "shows a confirming Delete button only on the signed-in author's comments" do
      sign_in marko
      get event_path(event)

      expect(delete_forms.map { it["action"] }).to eq([ event_comment_path(event, own) ])
      expect(delete_forms.first["data-turbo-confirm"]).to eq("Delete this comment?")
      expect(delete_forms.first.at_css("button").text).to eq("Delete")
    end

    it "shows no Delete button to a guest" do
      get event_path(event)
      expect(delete_forms).to be_empty
    end
  end
end
