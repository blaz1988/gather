# PD-1: RSVPs with a waitlist (delivery report)

*Status: delivered · Revision 3 · Created by Ivan Blažević <ivan.blazevic@rubycode.co> · 29 September 2026*

## Summary

5 of 5 tickets merged. 33 of 33 acceptance criteria are proven by a passing scenario.

## Tickets and pull requests

| # | Ticket | Status | Pull request | Merge commit | Approved by |
| --- | --- | --- | --- | --- | --- |
| T1 | Migration: Create rsvps table | merged | [#8](https://github.com/blaz1988/gather/pull/8) | bafbdf1 | Ivan Blažević <ivan.blazevic@rubycode.co> |
| T2 | Add Rsvp model and Event rules for RSVP, cancel, waitlist and promotion | merged | [#9](https://github.com/blaz1988/gather/pull/9) | a30c1ab | Ivan Blažević <ivan.blazevic@rubycode.co> |
| T3 | Let signed-in people RSVP, join the waitlist and cancel from the event page | merged | [#11](https://github.com/blaz1988/gather/pull/11) | 75bf79d | Ivan Blažević <ivan.blazevic@rubycode.co> |
| T4 | Show the organizer who is going and who is waiting | merged | [#12](https://github.com/blaz1988/gather/pull/12) | 1bdb205 | Ivan Blažević <ivan.blazevic@rubycode.co> |
| T5 | Show seats left on the events index | merged | [#10](https://github.com/blaz1988/gather/pull/10) | 09b73f3 | Ivan Blažević <ivan.blazevic@rubycode.co> |

## Acceptance criteria and proof

Cucumber, run 29 Sep 2026 22:43 on commit `1bdb205`: `bundle exec cucumber --tags "@pd-1-t1 or @pd-1-t2 or @pd-1-t3 or @pd-1-t4 or @pd-1-t5"`

| AC | Criterion | Scenario | Result |
| --- | --- | --- | --- |
| T1.1 | Running bin/rails db:migrate creates the rsvps table with event_id, user_id, status, created_at and updated_at, all NOT NULL, and status has no default | Migrating creates the rsvps table (`features/pd-1-rsvps-with-a-waitlist/t1.feature:11`) | passed |
| T1.2 | Inserting a second row with the same event_id and user_id fails with ActiveRecord::RecordNotUnique through the index index_rsvps_on_event_id_and_user_id | A person can have only one row per event (`features/pd-1-rsvps-with-a-waitlist/t1.feature:17`) | passed |
| T1.3 | Inserting a row with a status other than 'going' or 'waitlisted' fails at the database because of the check constraint rsvps_status_check | The status must be going or waitlisted (`features/pd-1-rsvps-with-a-waitlist/t1.feature:24`) | passed |
| T1.4 | The indexes index_rsvps_on_event_id_and_status_and_created_at and index_rsvps_on_user_id exist | Seat and per-person lookups are indexed (`features/pd-1-rsvps-with-a-waitlist/t1.feature:29`) | passed |
| T1.5 | Inserting a row that points to a missing event or user fails the foreign key check, and neither foreign key cascades on delete | Rows must point at an existing event and person (`features/pd-1-rsvps-with-a-waitlist/t1.feature:34`); Deleting an event or person does not cascade to rsvps (`features/pd-1-rsvps-with-a-waitlist/t1.feature:41`) | passed |
| T1.6 | bin/rails db:rollback drops the rsvps table and leaves events, users and sessions unchanged | Rolling back drops only the rsvps table (`features/pd-1-rsvps-with-a-waitlist/t1.feature:51`) | passed |
| T2.1 | An event with capacity 3 and no RSVPs has 3 seats left, is not full, and has an empty waitlist | An event nobody has RSVPed to has every seat left (`features/pd-1-rsvps-with-a-waitlist/t2.feature:10`) | passed |
| T2.2 | For an event with capacity 2, four people calling rsvp in turn get going, going, waitlisted #1 and waitlisted #2, and going RSVPs have a waitlist_position of nil | People beyond capacity join the waitlist in turn (`features/pd-1-rsvps-with-a-waitlist/t2.feature:16`) | passed |
| T2.3 | Calling rsvp twice for the same person returns the same record and changes neither the going count nor the waitlisted count | RSVPing twice changes nothing (`features/pd-1-rsvps-with-a-waitlist/t2.feature:25`); RSVPing twice from the waitlist changes nothing (`features/pd-1-rsvps-with-a-waitlist/t2.feature:32`) | passed |
| T2.4 | When several threads race for the last seat of an event, exactly one RSVP is going, the rest are waitlisted, and the going count never exceeds capacity | Several people race for the last seat (`features/pd-1-rsvps-with-a-waitlist/t2.feature:40`) | passed |
| T2.5 | Destroying a going RSVP promotes only the oldest waitlisted RSVP to going. Destroying a waitlisted RSVP promotes nobody and moves everyone behind it up one position | Cancelling a going RSVP promotes only the oldest waitlisted RSVP (`features/pd-1-rsvps-with-a-waitlist/t2.feature:47`); Leaving the waitlist promotes nobody and moves the line up (`features/pd-1-rsvps-with-a-waitlist/t2.feature:55`) | passed |
| T2.6 | rsvp returns nil and creates no row when the user is the event's organizer or when the event's starts_at has passed | The organizer cannot RSVP to their own event (`features/pd-1-rsvps-with-a-waitlist/t2.feature:63`); Nobody can RSVP once the event has started (`features/pd-1-rsvps-with-a-waitlist/t2.feature:69`) | passed |
| T2.7 | Destroying a going user promotes the next waitlisted person, destroying an organizer removes their events' RSVPs without errors, and seats_left is 0 rather than negative when capacity is below the going count | Deleting a going person promotes the next waitlisted person (`features/pd-1-rsvps-with-a-waitlist/t2.feature:76`); Deleting an organizer removes their events' RSVPs (`features/pd-1-rsvps-with-a-waitlist/t2.feature:83`); Seats left never goes below zero (`features/pd-1-rsvps-with-a-waitlist/t2.feature:89`) | passed |
| T3.1 | A guest opening "Ruby Zagreb Meetup #42" with 3 seats sees "Seats left: 3 of 3" and a "Sign in to RSVP" link, and sees no "RSVP" button | A guest sees the seats left and a sign-in link (`features/pd-1-rsvps-with-a-waitlist/t3.feature:10`) | passed |
| T3.2 | A signed-in person who clicks "RSVP" sees "You're going", sees "Seats left: 2 of 3" and sees a "Cancel RSVP" button | A signed-in person RSVPs (`features/pd-1-rsvps-with-a-waitlist/t3.feature:18`) | passed |
| T3.3 | When 3 people are going, a fourth person sees "Full" and a "Join waitlist" button, and after clicking it sees "You're #1 on the waitlist" | A fourth person joins the waitlist of a full event (`features/pd-1-rsvps-with-a-waitlist/t3.feature:27`) | passed |
| T3.4 | When a going person clicks "Cancel RSVP", they see "Your RSVP was cancelled.", and the person who was #1 on the waitlist sees "You're going" when they open the event | Cancelling an RSVP gives the seat to the first person waiting (`features/pd-1-rsvps-with-a-waitlist/t3.feature:37`) | passed |
| T3.5 | A waitlisted person who clicks "Leave waitlist" no longer sees a waitlist position and sees the "Join waitlist" button again | A waitlisted person leaves the waitlist (`features/pd-1-rsvps-with-a-waitlist/t3.feature:48`) | passed |
| T3.6 | The organizer sees no RSVP button on their own event, and nobody sees an RSVP or cancel button on an event that has already started | The organizer sees no RSVP button on their own event (`features/pd-1-rsvps-with-a-waitlist/t3.feature:57`); Nobody sees RSVP buttons on an event that has started (`features/pd-1-rsvps-with-a-waitlist/t3.feature:72`); Nobody sees RSVP buttons on an event that has started (`features/pd-1-rsvps-with-a-waitlist/t3.feature:73`); Nobody sees RSVP buttons on an event that has started (`features/pd-1-rsvps-with-a-waitlist/t3.feature:74`); A guest sees no RSVP link on an event that has started (`features/pd-1-rsvps-with-a-waitlist/t3.feature:77`) | passed |
| T3.7 | A guest who sends POST or DELETE to /events/:id/rsvp is redirected to sign-in and nothing changes. Extra user_id or status params are ignored, and an unknown event id returns 404 | A guest cannot RSVP or cancel by sending requests directly (`features/pd-1-rsvps-with-a-waitlist/t3.feature:84`); Extra user_id and status params are ignored (`features/pd-1-rsvps-with-a-waitlist/t3.feature:94`); An unknown event returns 404 (`features/pd-1-rsvps-with-a-waitlist/t3.feature:104`) | passed |
| T4.1 | Organizer Ana sees "Going (3)" followed by the three attendees' names in the order they RSVPed | The organizer sees who is going in the order they RSVPed (`features/pd-1-rsvps-with-a-waitlist/t4.feature:11`) | passed |
| T4.2 | Organizer Ana sees "Waitlist (1)" with "#1" next to the name of the person who is waiting | The organizer sees who is waiting and their position (`features/pd-1-rsvps-with-a-waitlist/t4.feature:17`) | passed |
| T4.3 | After a going attendee cancels, Ana sees the promoted person under Going and the waitlist count goes down by one | A cancellation moves the first person waiting to Going (`features/pd-1-rsvps-with-a-waitlist/t4.feature:24`) | passed |
| T4.4 | Marko, who is signed in but is not the organizer, sees neither the "Going" nor the "Waitlist" list, and sees no other attendee's name | A signed-in person who is not the organizer sees no names (`features/pd-1-rsvps-with-a-waitlist/t4.feature:32`) | passed |
| T4.5 | A guest sees neither the "Going" nor the "Waitlist" list | A guest sees no attendee lists (`features/pd-1-rsvps-with-a-waitlist/t4.feature:41`) | passed |
| T4.6 | No attendee's email address appears anywhere on the event page, including for the organizer | No email address appears on the event page (`features/pd-1-rsvps-with-a-waitlist/t4.feature:55`); No email address appears on the event page (`features/pd-1-rsvps-with-a-waitlist/t4.feature:56`) | passed |
| T4.7 | The organizer's list shows no controls to remove or reorder people | The organizer's list has no remove or reorder controls (`features/pd-1-rsvps-with-a-waitlist/t4.feature:59`) | passed |
| T5.1 | An upcoming event with capacity 3 and no RSVPs shows "3 of 3 seats left" on the events page | An event nobody has RSVPed to shows every seat left (`features/pd-1-rsvps-with-a-waitlist/t5.feature:10`) | passed |
| T5.2 | After one person RSVPs, the events page shows "2 of 3 seats left" for that event | An RSVP takes a seat (`features/pd-1-rsvps-with-a-waitlist/t5.feature:15`) | passed |
| T5.3 | An event where every seat is taken shows "Full" on the events page | An event with every seat taken shows Full (`features/pd-1-rsvps-with-a-waitlist/t5.feature:21`) | passed |
| T5.4 | Waitlisted RSVPs do not reduce the seats left shown on the events page | Waitlisted RSVPs do not take seats (`features/pd-1-rsvps-with-a-waitlist/t5.feature:28`) | passed |
| T5.5 | An event whose capacity was lowered below its going count shows "Full" and never a negative number | Lowering capacity below the going count shows Full, never a negative number (`features/pd-1-rsvps-with-a-waitlist/t5.feature:35`) | passed |
| T5.6 | Rendering the events page with several events runs a single query against rsvps, however many events are listed | The events page counts seats for every event in a single query (`features/pd-1-rsvps-with-a-waitlist/t5.feature:43`) | passed |

## Checks run on each pull request

- **T1**: all checks passed
- **T2**: all checks passed
- **T3**: all checks passed
- **T4**: all checks passed
- **T5**: all checks passed

## Approvals

| When | Subject | Role | Decision | By | Note |
| --- | --- | --- | --- | --- | --- |
| 29 Sep 2026 21:32 | plan r3 | review | approved | Ivan Blažević <ivan.blazevic@rubycode.co> | Read it end to end. Decisions recorded under Outstanding questions. |
| 29 Sep 2026 21:43 | plan r3 | tickets:review | approved | Ivan Blažević <ivan.blazevic@rubycode.co> |  |
| 29 Sep 2026 22:03 | T1 pull request | pr | approved | Ivan Blažević <ivan.blazevic@rubycode.co> | Read the migration and the feature. Matches the plan. |
| 29 Sep 2026 22:14 | T2 pull request | pr | approved | Ivan Blažević <ivan.blazevic@rubycode.co> | Race test verified to fail without the transaction. |
| 29 Sep 2026 22:28 | T3 pull request | pr | approved | Ivan Blažević <ivan.blazevic@rubycode.co> | Tried RSVP and cancel on the branch locally. |
| 29 Sep 2026 22:32 | T5 pull request | pr | rejected | Ivan Blažević <ivan.blazevic@rubycode.co> | Two things. T3 is merged, so merge main into this branch and run RuboCop, RSpec and Cucumber again. And seats_left_label repeats the clamp in Event#seats_left: let Event#seats_left take a preloaded going count, and have the helper use it, so the rule lives in one place. |
| 29 Sep 2026 22:38 | T5 pull request | pr | approved | Ivan Blažević <ivan.blazevic@rubycode.co> | Merged main, seats-left rule now lives on Event. |
| 29 Sep 2026 22:39 | T4 pull request | pr | rejected | Ivan Blažević <ivan.blazevic@rubycode.co> | T5 is merged, so merge main into this branch and run RuboCop, RSpec and Cucumber again. |
| 29 Sep 2026 22:42 | T4 pull request | pr | approved | Ivan Blažević <ivan.blazevic@rubycode.co> | Names only, organizer only. |

## Timeline

- 29 Sep 2026 21:00 · plan.drafted · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:31 · plan.revised · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:32 · plan.revised · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:32 · plan.submitted · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:32 · plan.approved · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:34 · tickets.drafted · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:37 · tickets.drafted · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:43 · tickets.approved · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:43 · ticket.issue_created T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:43 · ticket.issue_created T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:43 · ticket.issue_created T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:43 · ticket.issue_created T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:43 · ticket.issue_created T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:44 · ticket.agent_started T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 21:50 · ticket.pr_opened T1 · cursor-agent
- 29 Sep 2026 21:53 · ticket.reviewed T1 · Ivan Blazevic <ivan.blazevic@lockthreat.com>
- 29 Sep 2026 21:54 · ticket.reviewed T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:03 · ticket.reviewed T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:03 · ticket.pr_approved T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:03 · ticket.reviewed T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:03 · ticket.merged T1 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:04 · ticket.agent_started T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:09 · ticket.pr_opened T2 · cursor-agent
- 29 Sep 2026 22:13 · ticket.reviewed T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:14 · ticket.reviewed T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:14 · ticket.pr_approved T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:14 · ticket.reviewed T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:14 · ticket.merged T2 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:14 · ticket.agent_started T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:14 · ticket.agent_started T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:17 · ticket.pr_opened T5 · cursor-agent
- 29 Sep 2026 22:20 · ticket.pr_opened T3 · cursor-agent
- 29 Sep 2026 22:27 · ticket.reviewed T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:28 · ticket.reviewed T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:28 · ticket.pr_approved T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:28 · ticket.reviewed T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:28 · ticket.merged T3 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:31 · ticket.reviewed T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:32 · ticket.changes_requested T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:32 · ticket.agent_started T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:33 · ticket.pr_opened T5 · cursor-agent
- 29 Sep 2026 22:36 · ticket.pr_opened T4 · cursor-agent
- 29 Sep 2026 22:38 · ticket.reviewed T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:38 · ticket.reviewed T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:38 · ticket.pr_approved T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:38 · ticket.reviewed T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:38 · ticket.merged T5 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:39 · ticket.reviewed T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:39 · ticket.changes_requested T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:41 · ticket.pr_opened T4 · cursor-agent
- 29 Sep 2026 22:41 · ticket.reviewed T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:42 · ticket.reviewed T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:42 · ticket.pr_approved T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:42 · ticket.reviewed T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:42 · ticket.merged T4 · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:42 · plan.delivered · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:43 · evidence.recorded · Ivan Blažević <ivan.blazevic@rubycode.co>
- 29 Sep 2026 22:43 · report.written · Ivan Blažević <ivan.blazevic@rubycode.co>

## The approved plan

The plan this delivery implements is in `plan.md`, revision 3.
