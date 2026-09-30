@pd-3-t5
Feature: Let authors delete their own comments
  Authors delete a comment they posted, to remove a question that was
  answered or a mistake they made.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 30 seats
    And "Marko Horvat" commented "Is there parking nearby?" on "Ruby Zagreb Meetup #42"

  @ac-1
  Scenario: An author deletes their own comment after confirming
    Given I am signed in as "Marko Horvat"
    When I open the event "Ruby Zagreb Meetup #42"
    And I click "Delete" on the comment by "Marko Horvat" and confirm "Delete this comment?"
    Then I am on the comments section of "Ruby Zagreb Meetup #42"
    And I should see "Comment deleted."
    And I should see "Comments (0)"
    And there is 0 comments rows

  @ac-2
  Scenario: A signed-in person sees no Delete button on other people's comments
    Given I am signed in as "Iva Babić"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see "Is there parking nearby?"
    And I should not see a "Delete" button

  @ac-3
  Scenario: Someone who is neither author nor organizer cannot delete by sending the request directly
    Given I am signed in as "Iva Babić"
    When I send a DELETE for the comment by "Marko Horvat" to "Ruby Zagreb Meetup #42"
    Then I should see "You can't delete this comment."
    And there is 1 comments row

  @ac-4
  Scenario: A signed-out DELETE is sent to sign-in
    Given I am not signed in
    When I send a DELETE for the comment by "Marko Horvat" to "Ruby Zagreb Meetup #42"
    Then I am asked to sign in
    And there is 1 comments row

  @ac-5 @allow-rescue
  Scenario: A comment id sent through another event's URL returns 404
    Given "Ana Kovač" organizes "Rails Workshop" with 10 seats
    And I am signed in as "Marko Horvat"
    When I send a DELETE for the comment by "Marko Horvat" to "Rails Workshop"
    Then the response is 404 Not Found
    And there is 1 comments row

  @ac-6
  Scenario: Deleting a comment is logged
    Given I am signed in as "Marko Horvat"
    When I open the event "Ruby Zagreb Meetup #42"
    And I click "Delete" on the comment by "Marko Horvat" and confirm "Delete this comment?" while capturing the log
    Then the log has the line for deleting the comment by "Marko Horvat" on "Ruby Zagreb Meetup #42", deleted by "Marko Horvat"

  @ac-7
  Scenario: Showing Delete buttons adds no queries against events
    Given I am signed in as "Marko Horvat"
    When I open the event "Ruby Zagreb Meetup #42" while counting queries
    Then I should see 1 "Delete" button
    And 1 query ran against comments
    And I note how many queries ran against events
    Given "Marko Horvat" commented 9 more times on "Ruby Zagreb Meetup #42"
    When I open the event "Ruby Zagreb Meetup #42" while counting queries
    Then I should see 10 "Delete" buttons
    And 1 query ran against comments
    And the same number of queries ran against events as noted
