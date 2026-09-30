@pd-3-t2
Feature: Comment rules and deleting comments with their event or author
  A comment is a short, non-blank body on an event by a person. Comments go
  away with their event or their author, so deleting either never fails.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 3 seats
    And a person named "Marko Horvat"

  @ac-1
  Scenario: A comment with an event, an author and a body is valid
    When "Marko Horvat" writes "Is there parking nearby?" on "Ruby Zagreb Meetup #42"
    Then the comment is valid

  @ac-2
  Scenario Outline: A blank or whitespace-only body is invalid
    When "Marko Horvat" writes a body of "<body>" on "Ruby Zagreb Meetup #42"
    Then the comment is invalid with "Body can't be blank"

    Examples:
      | body              |
      | empty             |
      | spaces            |
      | newlines and tabs |

  @ac-2
  Scenario: The body is stripped before validation
    When "Marko Horvat" writes "   Is there parking nearby?   " on "Ruby Zagreb Meetup #42"
    Then the comment is valid
    And the comment body is "Is there parking nearby?"

  @ac-3
  Scenario: The body is at most 1,000 characters
    When "Marko Horvat" writes a 1000-character comment on "Ruby Zagreb Meetup #42"
    Then the comment is valid
    When "Marko Horvat" writes a 1001-character comment on "Ruby Zagreb Meetup #42"
    Then the comment is invalid with "Body is too long (maximum is 1000 characters)"

  @ac-4
  Scenario: Comments are listed oldest first, then in id order
    Given these comments on "Ruby Zagreb Meetup #42":
      | author       | body         | hours ago |
      | Marko Horvat | Posted 2nd   | 1         |
      | Iva Babić    | Posted 1st   | 2         |
      | Iva Babić    | Posted 3rd   | 1         |
    Then the comments on "Ruby Zagreb Meetup #42" are listed as:
      | Posted 1st |
      | Posted 2nd |
      | Posted 3rd |

  @ac-5
  Scenario: Destroying an event deletes its comments
    Given "Ana Kovač" organizes "Rails Workshop" with 2 seats
    And "Marko Horvat" commented "Is there parking nearby?" on "Ruby Zagreb Meetup #42"
    And "Ana Kovač" commented "Yes, behind the building." on "Ruby Zagreb Meetup #42"
    And "Marko Horvat" commented "Bring a laptop?" on "Rails Workshop"
    When the event "Ruby Zagreb Meetup #42" is destroyed
    Then no comments remain on the event "Ruby Zagreb Meetup #42"
    And there is 1 comments row

  @ac-6
  Scenario: Destroying a user deletes the comments they wrote on other people's events
    Given "Marko Horvat" commented "Is there parking nearby?" on "Ruby Zagreb Meetup #42"
    And "Iva Babić" commented "I can give a lift." on "Ruby Zagreb Meetup #42"
    When the person "Marko Horvat" is deleted
    Then no comments by "Marko Horvat" remain
    And there is 1 comments row

  @ac-7
  Scenario: Destroying an organizer whose event has other people's comments succeeds
    Given "Marko Horvat" commented "Is there parking nearby?" on "Ruby Zagreb Meetup #42"
    When the person "Ana Kovač" is deleted
    Then the event "Ruby Zagreb Meetup #42" no longer exists
    And no comments remain on the event "Ruby Zagreb Meetup #42"
    And there is 0 comments rows
