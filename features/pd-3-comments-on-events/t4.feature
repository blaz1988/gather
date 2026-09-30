@pd-3-t4
Feature: Post a comment on an event
  Signed-in people post a comment on an event page to ask the organizer and
  other attendees a question, so the answer stays visible to everyone.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 30 seats

  @ac-1
  Scenario: A signed-in person posts a question
    Given I am signed in as "Marko Horvat"
    When I open the event "Ruby Zagreb Meetup #42"
    And I post the comment "Is there parking nearby?"
    Then I am on the comments section of "Ruby Zagreb Meetup #42"
    And I should see "Comment posted."
    And the comments are listed as:
      | author       | body                     |
      | Marko Horvat | Is there parking nearby? |

  @ac-2
  Scenario: A signed-in person sees a required, length-limited comment box
    Given I am signed in as "Marko Horvat"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see the comment form
    And the comment box is required with a maxlength of 1000

  @ac-3
  Scenario: A signed-out visitor is invited to sign in instead
    Given I am not signed in
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see a "Sign in to comment" link
    And I should not see the comment form
    When I click "Sign in to comment"
    Then I am asked to sign in

  @ac-4
  Scenario: A signed-out visitor cannot post by sending the request directly
    Given I am not signed in
    When I send a comment "Is there parking nearby?" to "Ruby Zagreb Meetup #42"
    Then I am asked to sign in
    And there is 0 comments rows

  @ac-5
  Scenario Outline: A blank body is rejected
    Given I am signed in as "Marko Horvat"
    When I open the event "Ruby Zagreb Meetup #42"
    And I post a comment with a body of "<body>"
    Then I should see "Body can't be blank"
    And I should not see "Comment posted."
    And there is 0 comments rows

    Examples:
      | body              |
      | empty             |
      | spaces            |
      | newlines and tabs |

  @ac-6
  Scenario: A body over 1,000 characters is rejected
    Given I am signed in as "Marko Horvat"
    When I send a 1001-character comment to "Ruby Zagreb Meetup #42"
    Then I am on the comments section of "Ruby Zagreb Meetup #42"
    And I should see "Body is too long (maximum is 1000 characters)"
    And there is 0 comments rows

  @ac-7
  Scenario: Extra user_id, event_id and created_at params are ignored
    Given "Ana Kovač" organizes "Rails Workshop" with 10 seats
    And I am signed in as "Marko Horvat"
    When I send a comment to "Ruby Zagreb Meetup #42" as "Ana Kovač" on "Rails Workshop" created at "2020-01-01 09:00"
    Then the only comment is by "Marko Horvat" on "Ruby Zagreb Meetup #42", posted just now

  @ac-8 @allow-rescue
  Scenario: Posting to an unknown event returns 404
    Given I am signed in as "Marko Horvat"
    When I send a comment "Is there parking nearby?" to an unknown event
    Then the response is 404 Not Found
