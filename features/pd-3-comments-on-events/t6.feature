@pd-3-t6
Feature: Let organizers delete any comment on their event
  Organizers delete any comment on an event they organize, to remove spam
  or off-topic posts from their event page.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 30 seats
    And "Marko Horvat" commented "Is there parking nearby?" on "Ruby Zagreb Meetup #42"

  @ac-1
  Scenario: An organizer deletes another person's comment after confirming
    Given I am signed in as "Ana Kovač"
    When I open the event "Ruby Zagreb Meetup #42"
    And I click "Delete" on the comment by "Marko Horvat" and confirm "Delete this comment?"
    Then I am on the comments section of "Ruby Zagreb Meetup #42"
    And I should see "Comment deleted."
    And I should not see "Is there parking nearby?"
    And there is 0 comments rows

  @ac-2
  Scenario: An organizer sees a Delete button on every comment on their event
    Given "Iva Babić" commented "Can I bring a friend?" on "Ruby Zagreb Meetup #42"
    And "Ana Kovač" commented "Yes, behind the building." on "Ruby Zagreb Meetup #42"
    And I am signed in as "Ana Kovač"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see 3 "Delete" buttons

  @ac-3
  Scenario: The organizer of a different event cannot delete comments by others
    Given "Iva Babić" organizes "Rails Workshop" with 10 seats
    And I am signed in as "Iva Babić"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see "Is there parking nearby?"
    And I should not see a "Delete" button
    When I send a DELETE for the comment by "Marko Horvat" to "Ruby Zagreb Meetup #42"
    Then I should see "You can't delete this comment."
    And there is 1 comments row

  @ac-4
  Scenario: An organizer deleting someone else's comment is logged
    Given I am signed in as "Ana Kovač"
    When I open the event "Ruby Zagreb Meetup #42"
    And I click "Delete" on the comment by "Marko Horvat" and confirm "Delete this comment?" while capturing the log
    Then the log has the line for deleting the comment by "Marko Horvat" on "Ruby Zagreb Meetup #42", deleted by "Ana Kovač"

  @ac-5
  Scenario: Showing the organizer Delete buttons adds no queries per comment
    Given I am signed in as "Ana Kovač"
    When I open the event "Ruby Zagreb Meetup #42" while counting queries
    Then I should see 1 "Delete" button
    And 1 query ran against comments
    And I note how many queries ran against events
    And I note how many queries ran against users
    Given 9 more people commented on "Ruby Zagreb Meetup #42"
    When I open the event "Ruby Zagreb Meetup #42" while counting queries
    Then I should see 10 "Delete" buttons
    And 1 query ran against comments
    And the same number of queries ran against events as noted
    And the same number of queries ran against users as noted
