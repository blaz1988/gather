# Reuses comments_section from event_comments_steps.rb and counting_queries from events_index_steps.rb.

def comment_by(name)
  Comment.find_by!(user: person(name))
end

def add_reactions(comment, likes, dislikes)
  create_list(:comment_reaction, likes, comment: comment)
  create_list(:comment_reaction, dislikes, :dislike, comment: comment)
end

Given(/^the comment by "([^"]+)" has (\d+) likes? and (\d+) dislikes?$/) do |name, likes, dislikes|
  comment = comment_by(name)
  (@reacted_comment_ids ||= {})[name] = comment.id
  add_reactions(comment, likes.to_i, dislikes.to_i)
end

Given(/^every comment on "([^"]+)" has (\d+) likes? and (\d+) dislikes?$/) do |title, likes, dislikes|
  event_named(title).comments.each { add_reactions(it, likes.to_i, dislikes.to_i) }
end

Then("the comment by {string} shows {string} and {string}") do |name, like, dislike|
  reactions = comments_section.find(".comment", text: name).find(".comment__reactions")
  expect(reactions.text.squish).to eq("#{like} #{dislike}")
end

Then("the counts of the comment by {string} are inside its reactions element") do |name|
  comment = comment_by(name)
  counts = Comment.reaction_counts_for([ comment ])[comment.id]
  reactions = comments_section.find("##{ActionView::RecordIdentifier.dom_id(comment)}")
    .find("##{ActionView::RecordIdentifier.dom_id(comment, :reactions)}.comment__reactions")
  expect(reactions.text.squish).to eq("Like (#{counts["like"]}) Dislike (#{counts["dislike"]})")
end

Then("no reactions remain on the comment by {string}") do |name|
  comment_id = @reacted_comment_ids.fetch(name)
  expect(Comment.exists?(comment_id)).to be(false)
  expect(CommentReaction.where(comment_id:)).to be_empty
end

When("I note how many queries ran in total") do
  @noted_total_queries = @queries.size
end

Then("the same number of queries ran in total as noted") do
  expect(@queries.size).to eq(@noted_total_queries)
end
