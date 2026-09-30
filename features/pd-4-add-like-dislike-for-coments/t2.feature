@pd-4-t2
Feature: The comment_reactions table
  The database stores at most one like or dislike per person on a comment,
  and cleans up reactions itself when comments, events or people go away.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 3 seats
    And a person named "Marko Horvat"
    And "Ana Kovač" has a comments row on "Ruby Zagreb Meetup #42"

  @ac-1
  Scenario: Migrating creates the comment_reactions table
    Given the comment_reactions migration has run
    Then the comment_reactions table has NOT NULL columns "comment_id, user_id, kind, created_at, updated_at"
    And the comment_reactions kind column has no default

  @ac-2
  Scenario: Rows must point at an existing comment and person
    When I insert a comment_reactions row for a missing comment
    Then the insert fails with ActiveRecord::InvalidForeignKey
    When I insert a comment_reactions row for a missing person
    Then the insert fails with ActiveRecord::InvalidForeignKey

  @ac-3
  Scenario: The kind is either like or dislike
    When "Marko Horvat" inserts a "love" comment_reactions row on the comment by "Ana Kovač"
    Then the insert fails the check constraint "comment_reactions_kind_check"
    When "Marko Horvat" inserts a "like" comment_reactions row on the comment by "Ana Kovač"
    Then the insert succeeds
    When "Ana Kovač" inserts a "dislike" comment_reactions row on the comment by "Ana Kovač"
    Then the insert succeeds
    And there are 2 comment_reactions rows

  @ac-4
  Scenario: A person reacts to a comment at most once
    Given "Marko Horvat" has a "like" comment_reactions row on the comment by "Ana Kovač"
    When "Marko Horvat" inserts a "dislike" comment_reactions row on the comment by "Ana Kovač"
    Then the insert fails with ActiveRecord::RecordNotUnique
    And there is 1 comment_reactions row

  @ac-5
  Scenario: Reactions are indexed by comment and person, and by person
    Then the comment_reactions index "index_comment_reactions_on_comment_id_and_user_id" is unique on "comment_id, user_id"
    And the comment_reactions index "index_comment_reactions_on_user_id" is on "user_id"
    And no comment_reactions index is on "comment_id" alone

  @ac-6
  Scenario: Deleting a comment in SQL deletes its reactions
    Given "Marko Horvat" has a "like" comment_reactions row on the comment by "Ana Kovač"
    When I delete the comment by "Ana Kovač" directly in the database
    Then the delete succeeds
    And there are 0 comment_reactions rows

  @ac-7
  Scenario: Destroying an event deletes the reactions on its comments
    Given "Marko Horvat" has a "like" comment_reactions row on the comment by "Ana Kovač"
    And "Ana Kovač" has a "dislike" comment_reactions row on the comment by "Ana Kovač"
    When I destroy the event "Ruby Zagreb Meetup #42"
    Then the destroy succeeds
    And there are 0 comment_reactions rows

  @ac-8
  Scenario: Destroying a person deletes their reactions and the reactions on their comments
    Given "Marko Horvat" has a comments row on "Ruby Zagreb Meetup #42"
    And a person named "Ivana Babić"
    And "Marko Horvat" has a "like" comment_reactions row on the comment by "Ana Kovač"
    And "Ivana Babić" has a "dislike" comment_reactions row on the comment by "Marko Horvat"
    And "Ivana Babić" has a "like" comment_reactions row on the comment by "Ana Kovač"
    When I destroy the person "Marko Horvat"
    Then the destroy succeeds
    And there is 1 comment_reactions row
    And "Ivana Babić" still has a "like" comment_reactions row on the comment by "Ana Kovač"

  @ac-9
  Scenario: Rolling back drops only the comment_reactions table
    Given "Marko Horvat" has RSVPed to "Ruby Zagreb Meetup #42"
    And "Ana Kovač" has a session
    And "Marko Horvat" has a "like" comment_reactions row on the comment by "Ana Kovač"
    When I roll back the comment_reactions migration
    Then the comment_reactions table does not exist
    And the comments, events, users, rsvps and sessions tables are unchanged
