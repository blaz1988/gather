@pd-1-t3
Feature: RSVP, join the waitlist and cancel from the event page
  Signed-in people RSVP from the event page, see how many seats are left,
  join the waitlist when it's full and cancel to free their seat.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 3 seats

  @ac-1
  Scenario: A guest sees the seats left and a sign-in link
    Given I am not signed in
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see "Seats left: 3 of 3"
    And I should see a "Sign in to RSVP" link
    And I should not see a "RSVP" button

  @ac-2
  Scenario: A signed-in person RSVPs
    Given I am signed in as "Marko Horvat"
    When I open the event "Ruby Zagreb Meetup #42"
    And I click "RSVP"
    Then I should see "You're going"
    And I should see "Seats left: 2 of 3"
    And I should see a "Cancel RSVP" button

  @ac-3
  Scenario: A fourth person joins the waitlist of a full event
    Given "Marko Horvat, Iva Babić and Luka Perić" RSVP to "Ruby Zagreb Meetup #42" in turn
    And I am signed in as "Sara Novak"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see "Full"
    And I should see a "Join waitlist" button
    When I click "Join waitlist"
    Then I should see "You're #1 on the waitlist"

  @ac-4
  Scenario: Cancelling an RSVP gives the seat to the first person waiting
    Given "Marko Horvat, Iva Babić, Luka Perić and Sara Novak" RSVP to "Ruby Zagreb Meetup #42" in turn
    And I am signed in as "Marko Horvat"
    When I open the event "Ruby Zagreb Meetup #42"
    And I click "Cancel RSVP"
    Then I should see "Your RSVP was cancelled."
    Given I am signed in as "Sara Novak"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see "You're going"

  @ac-5
  Scenario: A waitlisted person leaves the waitlist
    Given "Marko Horvat, Iva Babić, Luka Perić and Sara Novak" RSVP to "Ruby Zagreb Meetup #42" in turn
    And I am signed in as "Sara Novak"
    When I open the event "Ruby Zagreb Meetup #42"
    And I click "Leave waitlist"
    Then I should not see "on the waitlist"
    And I should see a "Join waitlist" button

  @ac-6
  Scenario: The organizer sees no RSVP button on their own event
    Given I am signed in as "Ana Kovač"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see no RSVP buttons

  @ac-6
  Scenario Outline: Nobody sees RSVP buttons on an event that has started
    Given "Marko Horvat" has RSVPed to "Ruby Zagreb Meetup #42"
    And "Ruby Zagreb Meetup #42" started an hour ago
    And I am signed in as "<person>"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see no RSVP buttons

    Examples:
      | person       |
      | Marko Horvat |
      | Iva Babić    |
      | Ana Kovač    |

  @ac-6
  Scenario: A guest sees no RSVP link on an event that has started
    Given "Ruby Zagreb Meetup #42" started an hour ago
    And I am not signed in
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see no RSVP buttons

  @ac-7
  Scenario: A guest cannot RSVP or cancel by sending requests directly
    Given "Marko Horvat" has RSVPed to "Ruby Zagreb Meetup #42"
    And I am not signed in
    When I send a POST to the RSVP of "Ruby Zagreb Meetup #42"
    Then I am asked to sign in
    When I send a DELETE to the RSVP of "Ruby Zagreb Meetup #42"
    Then I am asked to sign in
    And "Ruby Zagreb Meetup #42" has 1 going and 0 waitlisted

  @ac-7
  Scenario: Extra user_id and status params are ignored
    Given "Marko Horvat, Iva Babić and Luka Perić" RSVP to "Ruby Zagreb Meetup #42" in turn
    And I am signed in as "Sara Novak"
    When I send a POST to the RSVP of "Ruby Zagreb Meetup #42" as "Marko Horvat" with status "going"
    Then "Sara Novak" is #1 on the waitlist for "Ruby Zagreb Meetup #42"
    When I send a DELETE to the RSVP of "Ruby Zagreb Meetup #42" as "Marko Horvat" with status "going"
    Then "Marko Horvat" is going to "Ruby Zagreb Meetup #42" with no waitlist position
    And "Ruby Zagreb Meetup #42" has 3 going and 0 waitlisted

  @ac-7 @allow-rescue
  Scenario: An unknown event returns 404
    Given I am signed in as "Marko Horvat"
    When I send a POST to the RSVP of an unknown event
    Then the response is 404 Not Found
