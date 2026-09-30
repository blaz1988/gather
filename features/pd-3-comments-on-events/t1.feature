@pd-3-t1
Feature: The comments table
  The database stores one comment per row, on an event and by a person,
  and guards that data itself before any code reads or writes it.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 3 seats
    And a person named "Marko Horvat"

  @ac-1
  Scenario: Migrating creates the comments table
    Given the comments migration has run
    Then the comments table has NOT NULL columns "event_id, user_id, body, created_at, updated_at"
    And the comments body column has no default

  @ac-2
  Scenario: Rows must point at an existing event and person
    When I insert a comments row for a missing event
    Then the insert fails with ActiveRecord::InvalidForeignKey
    When I insert a comments row for a missing person
    Then the insert fails with ActiveRecord::InvalidForeignKey

  @ac-3
  Scenario: The body must not be empty or only spaces
    When "Marko Horvat" inserts a comments row on "Ruby Zagreb Meetup #42" with the body ""
    Then the insert fails the check constraint "comments_body_length_check"
    When "Marko Horvat" inserts a comments row on "Ruby Zagreb Meetup #42" with the body "   "
    Then the insert fails the check constraint "comments_body_length_check"

  @ac-4
  Scenario: The body is at most 1,000 characters
    When "Marko Horvat" inserts a comments row on "Ruby Zagreb Meetup #42" with a 1001-character body
    Then the insert fails the check constraint "comments_body_length_check"
    When "Marko Horvat" inserts a comments row on "Ruby Zagreb Meetup #42" with a 1000-character body of accented letters and emoji
    Then the insert succeeds
    And there is 1 comments row

  @ac-5
  Scenario: Event page and per-person lookups are indexed
    Then the comments index "index_comments_on_event_id_and_created_at" is on "event_id, created_at"
    And the comments index "index_comments_on_user_id" is on "user_id"
    And no comments index is on "event_id" alone

  @ac-6
  Scenario: Deleting an event or person does not cascade to comments
    Given "Marko Horvat" has a comments row on "Ruby Zagreb Meetup #42"
    Then no comments foreign key cascades on delete
    When I delete the event "Ruby Zagreb Meetup #42" directly in the database
    Then the delete fails with ActiveRecord::InvalidForeignKey
    When I delete the person "Marko Horvat" directly in the database
    Then the delete fails with ActiveRecord::InvalidForeignKey
    And there is 1 comments row

  @ac-7
  Scenario: Rolling back drops only the comments table
    Given "Marko Horvat" has RSVPed to "Ruby Zagreb Meetup #42"
    And "Ana Kovač" has a session
    And "Marko Horvat" has a comments row on "Ruby Zagreb Meetup #42"
    When I roll back the comments migration
    Then the comments table does not exist
    And the events, users, rsvps and sessions tables are unchanged
