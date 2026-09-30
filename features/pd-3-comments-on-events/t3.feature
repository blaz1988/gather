@pd-3-t3
Feature: Comments on the event page
  Anyone can read the comments on an event page, with who wrote each one and when,
  so they can find answers to questions other people have already asked.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 30 seats

  @ac-1
  Scenario: A signed-out visitor sees each comment's author, posted time and body
    Given "Marko Horvat" commented "Is there parking nearby?" on "Ruby Zagreb Meetup #42" at "2026-09-30 15:19"
    And "Ana Kovač" commented "Yes, behind the building." on "Ruby Zagreb Meetup #42" at "2026-09-30 16:02"
    And I am not signed in
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see "Comments (2)"
    And the comments are listed as:
      | author       | body                      |
      | Marko Horvat | Is there parking nearby?  |
      | Ana Kovač    | Yes, behind the building. |
    And the comment by "Marko Horvat" was posted at "30 September 2026 · 15:19" in a time element dated "2026-09-30T15:19:00Z"
    And the comment by "Ana Kovač" was posted at "30 September 2026 · 16:02" in a time element dated "2026-09-30T16:02:00Z"

  @ac-2
  Scenario: Comments are listed oldest first
    Given these comments on "Ruby Zagreb Meetup #42":
      | author       | body                   | hours ago |
      | Iva Babić    | Will there be pizza?   | 1         |
      | Marko Horvat | Is there parking?      | 3         |
      | Luka Perić   | Can I bring a friend?  | 2         |
    When I open the event "Ruby Zagreb Meetup #42"
    Then the comments are listed as:
      | author       | body                  |
      | Marko Horvat | Is there parking?     |
      | Luka Perić   | Can I bring a friend? |
      | Iva Babić    | Will there be pizza?  |

  @ac-3
  Scenario: An event with no comments invites a question
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see "Comments (0)"
    And I should see "No comments yet. Ask a question."

  @ac-4
  Scenario: The posted time is shown in a time element with an ISO 8601 datetime
    Given "Marko Horvat" commented "Is there parking nearby?" on "Ruby Zagreb Meetup #42" at "2026-09-30 15:19:42"
    When I open the event "Ruby Zagreb Meetup #42"
    Then the comment by "Marko Horvat" was posted at "30 September 2026 · 15:19" in a time element dated "2026-09-30T15:19:42Z"

  @ac-5
  Scenario: An author with a blank name shows as Someone
    Given "Marko Horvat" commented "Is there parking nearby?" on "Ruby Zagreb Meetup #42"
    And "Marko Horvat" has a blank name, set with update_column
    When I open the event "Ruby Zagreb Meetup #42"
    Then the comments are listed as:
      | author  | body                     |
      | Someone | Is there parking nearby? |

  @ac-6
  Scenario: HTML in a comment is shown as literal text
    Given "Marko Horvat" commented on "Ruby Zagreb Meetup #42":
      """
      <script>alert(1)</script> <a href="javascript:alert(1)">x</a>
      """
    When I open the event "Ruby Zagreb Meetup #42"
    Then the comment by "Marko Horvat" reads:
      """
      <script>alert(1)</script> <a href="javascript:alert(1)">x</a>
      """
    And the comments section has no script or link elements

  @ac-7
  Scenario: Line breaks in a comment are kept
    Given "Marko Horvat" commented on "Ruby Zagreb Meetup #42":
      """
      Is there parking nearby?
      Or should I take the tram?

      Thanks!
      """
    When I open the event "Ruby Zagreb Meetup #42"
    Then the comment by "Marko Horvat" has the paragraphs:
      | Is there parking nearby? Or should I take the tram? |
      | Thanks!                                             |

  @ac-8
  Scenario: The event page loads comments and authors in a fixed number of queries
    Given "Marko Horvat" commented "Is there parking nearby?" on "Ruby Zagreb Meetup #42"
    When I open the event "Ruby Zagreb Meetup #42" while counting queries
    Then 1 query ran against comments
    And I note how many queries ran against users
    Given 9 more people commented on "Ruby Zagreb Meetup #42"
    When I open the event "Ruby Zagreb Meetup #42" while counting queries
    Then I should see "Comments (10)"
    And 1 query ran against comments
    And the same number of queries ran against users as noted
