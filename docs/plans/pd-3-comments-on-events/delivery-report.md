# PD-3: Comments on events (delivery report)

*Status: delivered · Revision 2 · Created by Ivan Blažević <ivan.blazevic@rubycode.co> · 30 September 2026*

## Summary

6 of 6 tickets merged. 42 of 42 acceptance criteria are proven by a passing scenario.

## Tickets and pull requests

| # | Ticket | Status | Pull request | Merge commit | Approved by |
| --- | --- | --- | --- | --- | --- |
| T1 | Migration: Create comments table | merged | [#40](https://github.com/blaz1988/gather/pull/40) | 28dc943 | Ivan Blažević <ivan.blazevic@rubycode.co> |
| T2 | Add Comment model and delete comments with their event or author | merged | [#41](https://github.com/blaz1988/gather/pull/41) | d6808f0 | Ivan Blažević <ivan.blazevic@rubycode.co> |
| T3 | Show comments on the event page | merged | [#42](https://github.com/blaz1988/gather/pull/42) | e5ea511 | Ivan Blažević <ivan.blazevic@rubycode.co> |
| T4 | Post a comment on an event | merged | [#43](https://github.com/blaz1988/gather/pull/43) | 5aa1c48 | Ivan Blažević <ivan.blazevic@rubycode.co> |
| T5 | Let authors delete their own comments | merged | [#44](https://github.com/blaz1988/gather/pull/44) | 9284d3e | Ivan Blažević <ivan.blazevic@rubycode.co> |
| T6 | Let organizers delete any comment on their event | merged | [#45](https://github.com/blaz1988/gather/pull/45) | efe49c9 | Ivan Blažević <ivan.blazevic@rubycode.co> |

## Acceptance criteria and proof

Cucumber, run 30 Sep 2026 15:01 on commit `efe49c9`: `bundle exec cucumber --tags "@pd-3-t1 or @pd-3-t2 or @pd-3-t3 or @pd-3-t4 or @pd-3-t5 or @pd-3-t6"`

| AC | Criterion | Scenario | Result |
| --- | --- | --- | --- |
| T1.1 | Migrating creates the comments table with NOT NULL columns event_id, user_id, body, created_at and updated_at, and body has no default | Migrating creates the comments table (`features/pd-3-comments-on-events/t1.feature:11`) | passed |
| T1.2 | Inserting a comments row for an event or user that does not exist fails with ActiveRecord::InvalidForeignKey | Rows must point at an existing event and person (`features/pd-3-comments-on-events/t1.feature:17`) | passed |
| T1.3 | Inserting a comments row with an empty or space-only body fails the check constraint comments_body_length_check | The body must not be empty or only spaces (`features/pd-3-comments-on-events/t1.feature:24`) | passed |
| T1.4 | Inserting a comments row with a 1,001-character body fails the check constraint comments_body_length_check, and a 1,000-character body containing accented letters and emoji is accepted | The body is at most 1,000 characters (`features/pd-3-comments-on-events/t1.feature:31`) | passed |
| T1.5 | The index index_comments_on_event_id_and_created_at is on event_id, created_at, the index index_comments_on_user_id is on user_id, and there is no index on event_id alone | Event page and per-person lookups are indexed (`features/pd-3-comments-on-events/t1.feature:39`) | passed |
| T1.6 | Neither comments foreign key cascades on delete: deleting an event or user that has a comments row directly in the database fails with ActiveRecord::InvalidForeignKey | Deleting an event or person does not cascade to comments (`features/pd-3-comments-on-events/t1.feature:45`) | passed |
| T1.7 | Rolling back the comments migration drops the comments table and leaves the events, users, rsvps and sessions tables unchanged | Rolling back drops only the comments table (`features/pd-3-comments-on-events/t1.feature:55`) | passed |
| T2.1 | A comment with an event, an author and a body is valid | A comment with an event, an author and a body is valid (`features/pd-3-comments-on-events/t2.feature:11`) | passed |
| T2.2 | A comment whose body is blank or only whitespace, including newlines and tabs, is invalid, because the body is stripped before validation | A blank or whitespace-only body is invalid (`features/pd-3-comments-on-events/t2.feature:22`); A blank or whitespace-only body is invalid (`features/pd-3-comments-on-events/t2.feature:23`); A blank or whitespace-only body is invalid (`features/pd-3-comments-on-events/t2.feature:24`); The body is stripped before validation (`features/pd-3-comments-on-events/t2.feature:27`) | passed |
| T2.3 | A comment of exactly 1,000 characters is valid, and one of 1,001 characters is invalid with the error 'Body is too long (maximum is 1000 characters)' | The body is at most 1,000 characters (`features/pd-3-comments-on-events/t2.feature:33`) | passed |
| T2.4 | Comments on an event are listed oldest first, and two comments with the same created_at are listed in id order | Comments are listed oldest first, then in id order (`features/pd-3-comments-on-events/t2.feature:40`) | passed |
| T2.5 | Destroying an event deletes its comments | Destroying an event deletes its comments (`features/pd-3-comments-on-events/t2.feature:52`) | passed |
| T2.6 | Destroying a user deletes the comments they wrote on other people's events | Destroying a user deletes the comments they wrote on other people's events (`features/pd-3-comments-on-events/t2.feature:62`) | passed |
| T2.7 | Destroying a user who organizes an event that has other people's comments succeeds without a foreign key error, and those comments are gone | Destroying an organizer whose event has other people's comments succeeds (`features/pd-3-comments-on-events/t2.feature:70`) | passed |
| T3.1 | A signed-out visitor opening an event with comments sees the heading 'Comments (2)' and each comment's author name, posted time and body | A signed-out visitor sees each comment's author, posted time and body (`features/pd-3-comments-on-events/t3.feature:10`) | passed |
| T3.2 | Comments are listed oldest first | Comments are listed oldest first (`features/pd-3-comments-on-events/t3.feature:24`) | passed |
| T3.3 | An event with no comments shows 'Comments (0)' and 'No comments yet. Ask a question.' | An event with no comments invites a question (`features/pd-3-comments-on-events/t3.feature:38`) | passed |
| T3.4 | The posted time is shown as '30 September 2026 · 15:19' inside a time element whose datetime attribute is the ISO 8601 timestamp | The posted time is shown in a time element with an ISO 8601 datetime (`features/pd-3-comments-on-events/t3.feature:44`) | passed |
| T3.5 | A comment whose author has a blank name, set with update_column, shows the author as 'Someone' | An author with a blank name shows as Someone (`features/pd-3-comments-on-events/t3.feature:50`) | passed |
| T3.6 | A comment body containing <script>alert(1)</script> and <a href="javascript:alert(1)">x</a> is shown as literal escaped text, and no script or link element is rendered | HTML in a comment is shown as literal text (`features/pd-3-comments-on-events/t3.feature:59`) | passed |
| T3.7 | A comment body with line breaks is shown as separate lines or paragraphs | Line breaks in a comment are kept (`features/pd-3-comments-on-events/t3.feature:72`) | passed |
| T3.8 | The page makes 1 query against comments, and the number of queries against users is the same for 1 comment as for 10 comments by different authors | The event page loads comments and authors in a fixed number of queries (`features/pd-3-comments-on-events/t3.feature:86`) | passed |
| T4.1 | A signed-in user who submits 'Is there parking nearby?' is taken back to the event's comments section and sees 'Comment posted.' and the comment with their name | A signed-in person posts a question (`features/pd-3-comments-on-events/t4.feature:10`) | passed |
| T4.2 | A signed-in user sees the comment form, and the textarea is required and has maxlength 1000 | A signed-in person sees a required, length-limited comment box (`features/pd-3-comments-on-events/t4.feature:21`) | passed |
| T4.3 | A signed-out visitor sees a 'Sign in to comment' link and no comment form, and following the link opens the sign-in page | A signed-out visitor is invited to sign in instead (`features/pd-3-comments-on-events/t4.feature:28`) | passed |
| T4.4 | A signed-out POST to the event's comments is redirected to the sign-in page, and no comment is created | A signed-out visitor cannot post by sending the request directly (`features/pd-3-comments-on-events/t4.feature:37`) | passed |
| T4.5 | Posting a blank or whitespace-only body creates no comment and shows the alert "Body can't be blank" | A blank body is rejected (`features/pd-3-comments-on-events/t4.feature:54`); A blank body is rejected (`features/pd-3-comments-on-events/t4.feature:55`); A blank body is rejected (`features/pd-3-comments-on-events/t4.feature:56`) | passed |
| T4.6 | Posting a 1,001-character body creates no comment and shows the alert 'Body is too long (maximum is 1000 characters)' | A body over 1,000 characters is rejected (`features/pd-3-comments-on-events/t4.feature:59`) | passed |
| T4.7 | Posting with extra user_id, event_id and created_at params creates a comment owned by the signed-in user on the event from the URL, with its own timestamp | Extra user_id, event_id and created_at params are ignored (`features/pd-3-comments-on-events/t4.feature:67`) | passed |
| T4.8 | Posting to an event that does not exist returns 404 | Posting to an unknown event returns 404 (`features/pd-3-comments-on-events/t4.feature:74`) | passed |
| T5.1 | An author clicks Delete on their own comment, confirms 'Delete this comment?', sees 'Comment deleted.', and the comment is gone | An author deletes their own comment after confirming (`features/pd-3-comments-on-events/t5.feature:11`) | passed |
| T5.2 | A signed-in user sees no Delete button on comments written by other people | A signed-in person sees no Delete button on other people's comments (`features/pd-3-comments-on-events/t5.feature:21`) | passed |
| T5.3 | A signed-in user who is neither author nor organizer and sends DELETE for someone else's comment gets 'You can't delete this comment.', and the comment remains | Someone who is neither author nor organizer cannot delete by sending the request directly (`features/pd-3-comments-on-events/t5.feature:28`) | passed |
| T5.4 | A signed-out DELETE is redirected to the sign-in page, and the comment remains | A signed-out DELETE is sent to sign-in (`features/pd-3-comments-on-events/t5.feature:35`) | passed |
| T5.5 | Sending DELETE for a comment id through a different event's URL returns 404, and the comment remains | A comment id sent through another event's URL returns 404 (`features/pd-3-comments-on-events/t5.feature:42`) | passed |
| T5.6 | Deleting a comment writes the log line 'Comment deleted: comment_id=<id> event_id=<event_id> author_id=<author_id> deleted_by=<current user id>' | Deleting a comment is logged (`features/pd-3-comments-on-events/t5.feature:50`) | passed |
| T5.7 | Showing Delete buttons adds no queries against events: the page still makes 1 query against comments, and the number of queries against events is the same for 1 comment as for 10 | Showing Delete buttons adds no queries against events (`features/pd-3-comments-on-events/t5.feature:57`) | passed |
| T6.1 | An organizer clicks Delete on another person's comment on their event, confirms, sees 'Comment deleted.', and the comment is gone | An organizer deletes another person's comment after confirming (`features/pd-3-comments-on-events/t6.feature:11`) | passed |
| T6.2 | An organizer sees a Delete button on every comment on their event | An organizer sees a Delete button on every comment on their event (`features/pd-3-comments-on-events/t6.feature:21`) | passed |
| T6.3 | The organizer of a different event sees no Delete button on comments by others, and sending DELETE gets 'You can't delete this comment.' while the comment remains | The organizer of a different event cannot delete comments by others (`features/pd-3-comments-on-events/t6.feature:29`) | passed |
| T6.4 | An organizer deleting someone else's comment writes a log line where deleted_by is the organizer's id and author_id is the comment author's id | An organizer deleting someone else's comment is logged (`features/pd-3-comments-on-events/t6.feature:40`) | passed |
| T6.5 | Viewed by the organizer, an event with 10 comments makes 1 query against comments, and the number of queries against events and users is the same as with 1 comment | Showing the organizer Delete buttons adds no queries per comment (`features/pd-3-comments-on-events/t6.feature:47`) | passed |

## Checks run on each pull request

- **T1**: all checks passed
- **T2**: all checks passed
- **T3**: all checks passed
- **T4**: all checks passed
- **T5**: all checks passed
- **T6**: all checks passed

## Tokens and cost

| Step | Ticket | Model | Input | Output | Cache | Time | Cost |
| --- | --- | --- | --- | --- | --- | --- | --- |
| plan drafted | - | claude-opus-5-5 | 109,186 | 28,978 | 0 | - | - |
| database_changes redrafted | - | claude-opus-5-5 | 37,218 | 2,503 | 0 | - | - |
| tickets drafted | - | claude-opus-5-5 | 81,453 | 8,474 | 0 | - | - |
| agent run | T1 | claude-opus-5-5 | 50 | 12,652 | 1.12M | 5.0 min | - |
| agent run | T2 | claude-opus-5-5 | 46 | 12,437 | 1.17M | 4.3 min | - |
| agent run | T3 | claude-opus-5-5 | 46 | 12,904 | 1.09M | 4.4 min | - |
| agent follow-up | T3 | claude-opus-5-5 | 14 | 3,566 | 378,444 | 1.3 min | - |
| agent run | T4 | claude-opus-5-5 | 46 | 13,419 | 1.23M | 4.5 min | - |
| agent run | T5 | claude-opus-5-5 | 56 | 13,438 | 1.48M | 5.0 min | - |
| agent run | T6 | claude-opus-5-5 | 36 | 7,440 | 805,096 | 3.2 min | - |

**Total: 7.62M tokens.** No price is set for claude-opus-5-5; add it to `config.token_prices` to see dollars.

## Approvals

| When | Subject | Role | Decision | By | Note |
| --- | --- | --- | --- | --- | --- |
| 30 Sep 2026 13:25 | plan r2 | review | approved | Ivan Blažević <ivan.blazevic@rubycode.co> |  |
| 30 Sep 2026 13:28 | plan r2 | tickets:review | approved | Ivan Blažević <ivan.blazevic@rubycode.co> |  |
| 30 Sep 2026 13:44 | T1 pull request | pr | approved | Ivan Blažević <ivan.blazevic@rubycode.co> |  |
| 30 Sep 2026 13:55 | T2 pull request | pr | approved | Ivan Blažević <ivan.blazevic@rubycode.co> | Read the model, the cascades and the specs. Matches the plan. |
| 30 Sep 2026 14:07 | T3 pull request | pr | rejected | Ivan Blažević <ivan.blazevic@rubycode.co> | Placement, outstanding question 1: comments go in the main column, directly below the About this event card, not in the sidebar. Keep the specs and scenarios passing. |
| 30 Sep 2026 14:17 | T3 pull request | pr | approved | Ivan Blažević <ivan.blazevic@rubycode.co> | Comments now sit in the main column below About this event, as decided. Read the partials and the specs. |
| 30 Sep 2026 14:28 | T4 pull request | pr | approved | Ivan Blažević <ivan.blazevic@rubycode.co> | Read the controller, the form and the specs. Author and event come from the session and the URL. |
| 30 Sep 2026 14:39 | T5 pull request | pr | approved | Ivan Blažević <ivan.blazevic@rubycode.co> | Only the author gets the Delete button and the destroy action checks it again. Read the specs. |
| 30 Sep 2026 14:48 | T6 pull request | pr | approved | Ivan Blažević <ivan.blazevic@rubycode.co> | One rule in deletable_by?, no extra queries on the page. Read the specs. |

## Timeline

- 30 Sep 2026 13:23 · plan.drafted · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:24 · plan.revised · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:25 · plan.submitted · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:25 · plan.approved · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:27 · tickets.drafted · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:28 · tickets.approved · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:28 · ticket.issue_created T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:28 · ticket.issue_created T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:28 · ticket.issue_created T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:28 · ticket.issue_created T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:28 · ticket.issue_created T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:28 · ticket.issue_created T6 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:28 · ticket.agent_started T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:39 · ticket.pr_opened T1 · cursor-agent
- 30 Sep 2026 13:39 · ticket.reviewed T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:44 · ticket.reviewed T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:44 · ticket.pr_approved T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:44 · ticket.reviewed T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:44 · ticket.merged T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:45 · ticket.agent_started T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:55 · ticket.pr_opened T2 · cursor-agent
- 30 Sep 2026 13:55 · ticket.reviewed T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:55 · ticket.reviewed T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:55 · ticket.pr_approved T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:55 · ticket.reviewed T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:55 · ticket.merged T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 13:56 · ticket.agent_started T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:07 · ticket.pr_opened T3 · cursor-agent
- 30 Sep 2026 14:07 · ticket.changes_requested T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:17 · ticket.pr_opened T3 · cursor-agent
- 30 Sep 2026 14:17 · ticket.reviewed T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:17 · ticket.reviewed T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:17 · ticket.pr_approved T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:17 · ticket.reviewed T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:17 · ticket.merged T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:17 · ticket.agent_started T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:28 · ticket.pr_opened T4 · cursor-agent
- 30 Sep 2026 14:28 · ticket.reviewed T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:28 · ticket.reviewed T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:28 · ticket.pr_approved T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:28 · ticket.reviewed T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:28 · ticket.merged T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:28 · ticket.agent_started T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:39 · ticket.pr_opened T5 · cursor-agent
- 30 Sep 2026 14:39 · ticket.reviewed T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:39 · ticket.reviewed T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:39 · ticket.pr_approved T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:39 · ticket.reviewed T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:39 · ticket.merged T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:39 · ticket.agent_started T6 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:48 · ticket.pr_opened T6 · cursor-agent
- 30 Sep 2026 14:48 · ticket.reviewed T6 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:48 · ticket.reviewed T6 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:48 · ticket.pr_approved T6 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:48 · ticket.reviewed T6 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:48 · ticket.merged T6 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:48 · plan.delivered · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:50 · evidence.recorded · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:51 · report.written · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:52 · evidence.recorded · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:53 · report.written · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:58 · evidence.recorded · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 14:59 · report.written · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 15:01 · evidence.recorded · Ivan Blažević <ivan.blazevic@rubycode.co>
- 30 Sep 2026 15:01 · report.written · Ivan Blažević <ivan.blazevic@rubycode.co>

## The approved plan

The plan this delivery implements is in `plan.md`, revision 2.
