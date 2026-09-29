@pd-1-t1
Feature: The rsvps table
  The database links one person to one event with a status of going or waitlisted,
  and guards that data itself before any code reads or writes it.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 3 seats
    And a person named "Marko Horvat"

  @ac-1
  Scenario: Migrating creates the rsvps table
    Given the database is migrated
    Then the rsvps table has NOT NULL columns "event_id, user_id, status, created_at, updated_at"
    And the rsvps status column has no default

  @ac-2
  Scenario: A person can have only one row per event
    Given "Marko Horvat" has a "going" rsvps row for "Ruby Zagreb Meetup #42"
    When I insert a "waitlisted" rsvps row for "Marko Horvat" and "Ruby Zagreb Meetup #42"
    Then the insert fails with ActiveRecord::RecordNotUnique
    And the rsvps index "index_rsvps_on_event_id_and_user_id" is unique on "event_id, user_id"

  @ac-3
  Scenario: The status must be going or waitlisted
    When I insert a "maybe" rsvps row for "Marko Horvat" and "Ruby Zagreb Meetup #42"
    Then the insert fails the check constraint "rsvps_status_check"

  @ac-4
  Scenario: Seat and per-person lookups are indexed
    Then the rsvps index "index_rsvps_on_event_id_and_status_and_created_at" is on "event_id, status, created_at"
    And the rsvps index "index_rsvps_on_user_id" is on "user_id"

  @ac-5
  Scenario: Rows must point at an existing event and person
    When I insert a "going" rsvps row for a missing event
    Then the insert fails with ActiveRecord::InvalidForeignKey
    When I insert a "going" rsvps row for a missing person
    Then the insert fails with ActiveRecord::InvalidForeignKey

  @ac-5
  Scenario: Deleting an event or person does not cascade to rsvps
    Given "Marko Horvat" has a "going" rsvps row for "Ruby Zagreb Meetup #42"
    Then no rsvps foreign key cascades on delete
    When I delete the event "Ruby Zagreb Meetup #42" directly in the database
    Then the delete fails with ActiveRecord::InvalidForeignKey
    When I delete the person "Marko Horvat" directly in the database
    Then the delete fails with ActiveRecord::InvalidForeignKey
    And there is 1 rsvps row

  @ac-6
  Scenario: Rolling back drops only the rsvps table
    Given "Ana Kovač" has a session
    When I roll back the rsvps migration
    Then the rsvps table does not exist
    And the events, users and sessions tables are unchanged
