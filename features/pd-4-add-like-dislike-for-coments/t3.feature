@pd-4-t3
Feature: Show like and dislike counts on every comment
  Everyone sees how many people liked and disliked each comment on an event
  page, to tell which comments others found helpful.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 30 seats
    And "Marko Horvat" commented "Is there parking nearby?" on "Ruby Zagreb Meetup #42"

  @ac-1
  Scenario: A guest sees zero counts on an existing comment with no reactions
    Given I am not signed in
    When I open the event "Ruby Zagreb Meetup #42"
    Then the comment by "Marko Horvat" shows "Like (0)" and "Dislike (0)"

  @ac-2
  Scenario: Each comment shows its own counts
    Given "Iva Babić" commented "Can I bring a friend?" on "Ruby Zagreb Meetup #42"
    And the comment by "Marko Horvat" has 2 likes and 1 dislike
    And the comment by "Iva Babić" has 0 likes and 3 dislikes
    When I open the event "Ruby Zagreb Meetup #42"
    Then the comment by "Marko Horvat" shows "Like (2)" and "Dislike (1)"
    And the comment by "Iva Babić" shows "Like (0)" and "Dislike (3)"

  @ac-3
  Scenario: Each comment's counts are inside its own reactions element
    Given "Iva Babić" commented "Can I bring a friend?" on "Ruby Zagreb Meetup #42"
    And the comment by "Iva Babić" has 1 like and 0 dislikes
    When I open the event "Ruby Zagreb Meetup #42"
    Then the counts of the comment by "Marko Horvat" are inside its reactions element
    And the counts of the comment by "Iva Babić" are inside its reactions element

  @ac-4
  Scenario: A guest follows the Sign in to react link to the sign-in page
    Given I am not signed in
    When I open the event "Ruby Zagreb Meetup #42"
    And I click "Sign in to react"
    Then I am asked to sign in
    And I should see "Sign in"

  @ac-5
  Scenario: Showing the counts adds no queries per comment
    Given the comment by "Marko Horvat" has 1 like and 1 dislike
    When I open the event "Ruby Zagreb Meetup #42" while counting queries
    Then 1 query ran against comment_reactions
    And I note how many queries ran in total
    Given 9 more people commented on "Ruby Zagreb Meetup #42"
    And every comment on "Ruby Zagreb Meetup #42" has 2 likes and 1 dislike
    When I open the event "Ruby Zagreb Meetup #42" while counting queries
    Then I should see "Comments (10)"
    And 1 query ran against comment_reactions
    And the same number of queries ran in total as noted

  @ac-6
  Scenario: An organizer deletes a comment that has reactions
    Given "Iva Babić" commented "Can I bring a friend?" on "Ruby Zagreb Meetup #42"
    And the comment by "Marko Horvat" has 2 likes and 1 dislike
    And the comment by "Iva Babić" has 1 like and 0 dislikes
    And I am signed in as "Ana Kovač"
    When I open the event "Ruby Zagreb Meetup #42"
    And I click "Delete" on the comment by "Marko Horvat" and confirm "Delete this comment?"
    Then I am on the comments section of "Ruby Zagreb Meetup #42"
    And I should see "Comment deleted."
    And I should not see "Is there parking nearby?"
    And the comment by "Iva Babić" shows "Like (1)" and "Dislike (0)"
    And no reactions remain on the comment by "Marko Horvat"
    And there is 1 comment_reactions row

  @ac-7
  Scenario: Posting and deleting comments still works next to reacted comments
    Given the comment by "Marko Horvat" has 1 like and 0 dislikes
    And I am signed in as "Iva Babić"
    When I open the event "Ruby Zagreb Meetup #42"
    And I post the comment "Can I bring a friend?"
    Then I should see "Comment posted."
    And the comments are listed as:
      | author       | body                     |
      | Marko Horvat | Is there parking nearby? |
      | Iva Babić    | Can I bring a friend?    |
    And the comment by "Iva Babić" shows "Like (0)" and "Dislike (0)"
    When I click "Delete" on the comment by "Iva Babić" and confirm "Delete this comment?"
    Then I should see "Comment deleted."
    And the comment by "Marko Horvat" shows "Like (1)" and "Dislike (0)"
