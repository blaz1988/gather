# PD-4: Add like dislike for coments

# Overview

## What

we are building additoanl featire for comemnt section, jsut simpel like dislike option.
Every comment on an event page gets two buttons, Like and Dislike, each showing a count.
A signed-in user can like or dislike any comment. They can switch between the two, or take their reaction back.
Each user has at most one reaction per comment.

## Why

user want to ahv eoption to praise adn liek good comments or to dislike bad one

# Architectural changes

### Scope: what is being built
The team's "What" answer was 13 words ("simple like dislike option" for the comment section). The plan cannot edit the team's own answer, so it proposes a fuller one for the team to adopt (see Decisions) and builds against this scope:
- Every comment on an event page gets two buttons, **Like** and **Dislike**, each showing a count.
- A signed-in user can like or dislike any comment. They can switch between the two, or take their reaction back.
- Each user has at most one reaction per comment.
- Guests see the counts but must sign in to react.
- Clicking a button updates the counts in place without reloading the page.
- Out of scope: sorting comments by likes, notifications to authors, showing who reacted, reactions on events or RSVPs, and moderation tools.

### Target design
Add a new table, `comment_reactions`, with one row per (comment, user). A row holds a `kind` of `like` or `dislike`. A user has at most one reaction per comment. Clicking the other button switches the kind, and clicking the active button removes the reaction.

The counts are **not** stored on `comments`. They are worked out when the page is rendered, with one grouped query. This matches how `EventsController#index` already computes `@going_counts`. It also means nothing changes on existing `comments` rows and nothing needs a backfill.

### Data flow
1. **Rendering the event page.** `EventsController#show` loads `@comments` as it does today. It then runs two extra queries:
   - `CommentReaction.where(comment: @comments).group(:comment_id, :kind).count` to get the like and dislike counts for every comment.
   - `Current.user.comment_reactions.where(comment: @comments).pluck(:comment_id, :kind).to_h` to get the viewer's own reactions. This only runs when someone is signed in.

   Both results are passed as locals down to `comments/_comment`. That partial renders a new partial, `comments/_reactions`, wrapped in an element with id `dom_id(comment, :reactions)`.
2. **Reacting.** Each reaction button is a `button_to` form, so Rails includes a CSRF token and Turbo submits it with fetch (the 'ajax' part).
   - Like or Dislike when not already chosen: `PUT /events/:event_id/comments/:comment_id/reaction` with `kind=like` or `kind=dislike`.
   - Clicking the active button: `DELETE` to the same URL.
3. **Handling the request.** `CommentReactionsController` looks up the comment through `@event.comments.find(params[:comment_id])`, the same scoping `CommentsController#destroy` uses. It calls a model method that inserts or updates the row. It then replies with:
   - a Turbo Stream that replaces only `dom_id(comment, :reactions)`, or
   - for non-Turbo clients, an HTML redirect to `event_path(@event, anchor: dom_id(comment))`.

   No custom JavaScript or Stimulus controller is needed.

### Keeping the existing shape
- The nesting follows the existing pattern: events, then comments, then a new singular `reaction` resource.
- Authentication uses the existing `Authentication` concern. The new controller does not call `allow_unauthenticated_access`, so guests are sent to sign-in, as `CommentsController` does today.
- The model method follows `Event#rsvp`: find or create, and `rescue ActiveRecord::RecordNotUnique` to handle a double click that inserts twice.

### How legacy data coexists
This change is purely additive. Existing comments simply have zero reactions and render as 0 likes and 0 dislikes. No column on `comments`, `events` or `users` is renamed, removed or backfilled, so the expand, dual-write, backfill and switch-reads phases have nothing to do. The only step is expand: create the table. There is no contract step.

Deleting comments needs care. `Event` and `User` delete comments with `delete_all`, which skips callbacks, so the reaction foreign keys must use `on_delete: :cascade` at the database level. Without that, deleting a user or an event would fail on a foreign key error once reactions exist.

## Database changes

### Phase 1: Expand. This is the only phase.
One migration: `db/migrate/<timestamp>_create_comment_reactions.rb`.

**New table `comment_reactions`**

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | integer | not null | auto | primary key |
| `comment_id` | integer | not null | none | FK to `comments.id`, `on_delete: :cascade` |
| `user_id` | integer | not null | none | FK to `users.id`, `on_delete: :cascade` |
| `kind` | string | not null | none | `like` or `dislike` |
| `created_at` | datetime | not null | none | timestamps |
| `updated_at` | datetime | not null | none | timestamps |

**Indexes**
- Unique on (`comment_id`, `user_id`), named `index_comment_reactions_on_comment_id_and_user_id`. This enforces one reaction per user per comment and serves the `WHERE comment_id IN (...)` grouped count.
- `user_id`, named `index_comment_reactions_on_user_id`. This serves the cascade when a user is deleted and the 'my reactions' lookup.

**Constraints**
- Check constraint `comment_reactions_kind_check`: `kind IN ('like', 'dislike')`. This mirrors `rsvps_status_check`.
- `add_foreign_key :comment_reactions, :comments, on_delete: :cascade`
- `add_foreign_key :comment_reactions, :users, on_delete: :cascade`

Sketch:
```ruby
create_table :comment_reactions do |t|
  t.references :comment, null: false, foreign_key: { on_delete: :cascade }, index: false
  t.references :user, null: false, foreign_key: { on_delete: :cascade }
  t.string :kind, null: false
  t.timestamps
  t.index %i[ comment_id user_id ], unique: true
  t.check_constraint "kind IN ('like', 'dislike')", name: "comment_reactions_kind_check"
end
```

### Existing tables
- `comments`, `events` and `users`: **no changes.** No columns are added, renamed or removed, so no `ignored_columns` step is needed.
- Counter-cache columns such as `comments.likes_count` are deliberately not added. If they are wanted later, they would be a separate expand, backfill, then switch-reads change.

### Rollback
`drop_table :comment_reactions` is safe because nothing else refers to the table. The UI must be reverted first, or in the same deploy.

## Application changes

### Model: `CommentReaction` — `app/models/comment_reaction.rb` (new)
- `belongs_to :comment` and `belongs_to :user`.
- `enum :kind, %w[ like dislike ].index_by(&:itself), validate: true`, the same style as `Rsvp#status`.
- `validates :user_id, uniqueness: { scope: :comment_id }`.

### Model: `Comment` — `app/models/comment.rb`
- Add `has_many :reactions, class_name: "CommentReaction", dependent: :delete_all`. The database cascade covers the `delete_all` paths from `Event` and `User`.
- Add `react(user, kind)`. It returns nil for a nil user. Otherwise it finds the user's reaction and updates its `kind`, or creates one. It rescues `ActiveRecord::RecordNotUnique` by re-finding and updating, following the pattern in `Event#rsvp`.
- Add `unreact(user)`, which removes the user's reaction if there is one.
- Add a class method `reaction_counts_for(comments)`. It returns `{ comment_id => { "like" => n, "dislike" => n } }` from a single grouped query.
- Whether authors and organizers may react depends on Decisions. If they may not, add `reactable_by?(user)` next to `deletable_by?`.

### Model: `User` — `app/models/user.rb`
- Add `has_many :comment_reactions, dependent: :delete_all`.

### Routes — `config/routes.rb`
```ruby
resources :comments, only: %i[ create destroy ] do
  resource :reaction, only: %i[ update destroy ], controller: "comment_reactions"
end
```
This produces `event_comment_reaction_path(event, comment)`.

### Controller: `CommentReactionsController` — `app/controllers/comment_reactions_controller.rb` (new)
- `before_action :set_comment`, which runs `@event = Event.find(params[:event_id])` and then `@comment = @event.comments.find(params[:comment_id])`.
- `update`: `kind = params.expect(:kind)`. If the kind is not in `CommentReaction.kinds`, respond `422` or redirect with an alert. Otherwise call `@comment.react(Current.user, kind)`.
- `destroy`: `@comment.unreact(Current.user)`.
- Both actions use `respond_to`:
  - `format.turbo_stream`: render `turbo_stream.replace(dom_id(@comment, :reactions), partial: "comments/reactions", locals: { comment: @comment, counts: ..., current_kind: ... })`.
  - `format.html`: `redirect_to event_path(@event, anchor: dom_id(@comment))`.
- No `allow_unauthenticated_access`, so guests are redirected to sign-in.

### Controller: `EventsController#show` — `app/controllers/events_controller.rb`
- Add `@reaction_counts = Comment.reaction_counts_for(@comments)`.
- Add `@my_reactions`, which is `Current.user.comment_reactions.where(comment: @comments).pluck(:comment_id, :kind).to_h` when signed in and `{}` for guests.

### Views
- `app/views/events/_comments.html.erb`: pass `locals: { reaction_counts: @reaction_counts, my_reactions: @my_reactions }` to the comment collection render.
- `app/views/comments/_comment.html.erb`: render `comments/reactions` below the body.
- `app/views/comments/_reactions.html.erb` (new): a wrapper `<div id="<%= dom_id(comment, :reactions) %>" class="comment__reactions">` containing:
  - For signed-in users, two `button_to` buttons: Like (count) and Dislike (count). The active one gets `aria-pressed="true"` and a modifier class. The active button submits `DELETE`, and the other submits `PUT` with `params: { kind: ... }`.
  - For guests, the counts as plain text or disabled buttons. Whether guests also see a sign-in link is settled under Decisions.
- `app/views/comment_reactions/update.turbo_stream.erb` and `destroy.turbo_stream.erb`, or inline `render turbo_stream:` in the controller.
- CSS for `.comment__reactions` goes in the existing stylesheet.

### Policies and jobs
The app has no policy layer (no Pundit or CanCan in `Gemfile`). Authorization stays as model predicate methods, like `deletable_by?`. No jobs are needed.

# Risks

## Security
- **Authentication.** `CommentReactionsController` inherits the `Authentication` concern's default `require_authentication`. Guests who send `PUT` or `DELETE` are redirected to `new_session_path` and nothing is written.
- **Authorization.** A user can only create, change or remove *their own* reaction. The row is always keyed on `Current.user` and never on a `user_id` from params. The comment is scoped through `@event.comments.find`, so a comment id cannot be combined with an unrelated event id. Rules on whether authors or organizers may react are settled under Decisions and would live in `Comment#reactable_by?`.
- **Input validation.** The only accepted param is `kind`, read with `params.expect(:kind)`. It is checked against the enum in the model, and the database check constraint `comment_reactions_kind_check` backs this up. `user_id`, `comment_id` and timestamp params in the body are ignored.
- **CSRF.** The buttons use `button_to`, so they carry the authenticity token. Turbo sends it with fetch requests.
- **Data exposure.** Only aggregate counts are shown. Who liked or disliked a comment is not shown to anyone, including the organizer. The viewer's own active state is only rendered for the viewer.
- **Abuse.** There is no rate limiting. Each user has one reaction per comment, so vote stuffing needs multiple accounts. That is the same exposure the app already has for comments.

Risk Level: LOW: the change adds one user-owned table behind existing authentication, reads only a whitelisted enum value, exposes only counts, and touches no existing columns or sensitive data.

## Decisions

Recorded before the UI and controller tickets (T3 to T5) start. The team gave no answer to any of the nine questions, so each one is marked **Default (no team answer)** and falls back to the default that T3 to T5 are written against. If the team later answers a question differently, update this section and the acceptance criteria of T3, T4 and T5 before they are picked up. For example, if authors may not react, T4 adds `Comment#reactable_by?(user)` next to `deletable_by?` in `app/models/comment.rb`.

1. **Rewritten "What" answer.** *Default (no team answer): adopt the plan's proposal.* "Add Like and Dislike buttons with live counts to every comment on an event page, so signed-in users can react to a comment, switch their reaction, or remove it, while guests only see the counts." (35 words.) The team's original 13-word answer above stays as written.
2. **Scope.** *Default (no team answer): the scope is confirmed as planned.* Each user has at most one reaction per comment. They can switch between Like and Dislike, or remove their reaction. Counts are visible to everyone, including guests. Sorting comments by reactions, notifications to authors, and lists of who reacted are out of scope.
3. **Authors reacting to their own comment.** *Default (no team answer): allowed.* Everyone who is signed in may react, including the comment's author. No `Comment#reactable_by?` is added.
4. **Event organizer reacting.** *Default (no team answer): allowed.* The organizer may react to any comment on their event, like any other signed-in user.
5. **Public dislike counts.** *Default (no team answer): public.* Both the like count and the dislike count are shown to everyone, signed in or not.
6. **What guests see.** *Default (no team answer): counts plus a "Sign in to react" link.* Guests see both counts as plain text, not as forms, and a "Sign in to react" link to `new_session_path`.
7. **Reactions after the event has started.** *Default (no team answer): reactions stay open.* Reacting, switching and removing still work after `starts_at`. There is no cutoff, unlike RSVPs.
8. **Logging reaction changes.** *Default (no team answer): one log line per change.* Each create, switch or removal writes one `Rails.logger.info` line with the comment id, the user id and the new kind (or "removed"). No audit table is added.
9. **Button design.** *Default (no team answer): text labels.* The buttons read "Like (n)" and "Dislike (n)", with no icons. They sit below the comment body and above the Delete button.

# Testing
The project uses RSpec (`spec/models`, `spec/requests`, `spec/db`) and Cucumber features under `features/` with FactoryBot. New tests follow those conventions.

### Factory
- `spec/factories/comment_reactions.rb`: `comment_reaction` with `comment`, `user` and `kind { "like" }`, plus a `:dislike` trait.

### Database: `spec/db/comment_reactions_table_spec.rb`
Follow the pattern in `spec/db/comments_table_spec.rb` and `spec/db/rsvps_table_spec.rb`:
- `kind` outside `like`/`dislike` is rejected by `comment_reactions_kind_check`.
- A duplicate (`comment_id`, `user_id`) raises `RecordNotUnique`.
- Null `comment_id`, `user_id` or `kind` is rejected.
- Deleting a comment with SQL removes its reactions.
- `Event#destroy`, which uses `delete_all` on comments, removes reactions and does not raise.
- `User#destroy` removes both that user's reactions and reactions on that user's comments.

### Model: `spec/models/comment_reaction_spec.rb` and `spec/models/comment_spec.rb`
- The enum validates `kind`, and uniqueness is scoped to the comment.
- `Comment#react` creates a like, switches a like to a dislike without creating a second row, and is idempotent for the same kind.
- `Comment#react` returns nil for a nil user.
- `Comment#react` handles a simulated `RecordNotUnique` race.
- `Comment#unreact` removes only the given user's reaction and does nothing when there is none.
- `Comment.reaction_counts_for` returns correct counts for several comments in one query, and zero for comments with no reactions, meaning legacy comments.
- `reactable_by?`, if introduced, covers the author, organizer, other user and guest cases.

### Request: `spec/requests/comment_reactions_spec.rb`
- A guest `PUT` or `DELETE` redirects to `new_session_path` and changes nothing.
- A signed-in `PUT kind=like` creates a reaction for `Current.user`. `PUT kind=dislike` switches it. `DELETE` removes it.
- A Turbo Stream request returns `turbo_stream.replace` targeting `dom_id(comment, :reactions)` with updated counts.
- An HTML request redirects to `event_path(event, anchor: dom_id(comment))`.
- An invalid `kind` such as `love` returns an error or alert and writes nothing.
- Forged `user_id` and `comment_id` params in the body are ignored, and the reaction belongs to the signed-in user.
- A comment id through another event's URL returns 404. An unknown event or comment returns 404.
- One user's `DELETE` does not remove another user's reaction.
- Author and organizer rules follow Decisions.

### Request: `spec/requests/comments_spec.rb` and the events show page
- The event page shows 0 likes and 0 dislikes for existing comments with no reactions (legacy data).
- A signed-in user sees their active reaction marked with `aria-pressed="true"`.
- A guest sees counts but no reaction forms.
- The event page query count does not grow with the number of comments (no N+1).
- Existing comment create and delete specs keep passing unchanged.

### Cucumber features: `features/pd-4-comment-reactions/`
- A signed-in member likes a comment, sees the count go up without a full page reload, then clicks again to remove it.
- A member switches from like to dislike, and both counts update.
- A guest sees counts and is sent to sign-in when trying to react.
- An organizer deletes a reacted comment, and the page still renders.
