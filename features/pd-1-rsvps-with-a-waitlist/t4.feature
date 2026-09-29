@pd-1-t4
Feature: Show the organizer who is going and who is waiting
  The organizer sees, in order, who is going and who is on the waitlist,
  so they know who to expect. Nobody else sees the names.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 3 seats
    And "Marko Horvat, Iva Babić, Luka Perić and Sara Novak" RSVP to "Ruby Zagreb Meetup #42" in turn

  @ac-1
  Scenario: The organizer sees who is going in the order they RSVPed
    Given I am signed in as "Ana Kovač"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see "Going (3)" followed by "Marko Horvat, Iva Babić and Luka Perić"

  @ac-2
  Scenario: The organizer sees who is waiting and their position
    Given I am signed in as "Ana Kovač"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see "Waitlist (1)" followed by "Sara Novak"
    And I should see "#1" next to "Sara Novak" on the waitlist

  @ac-3
  Scenario: A cancellation moves the first person waiting to Going
    Given "Marko Horvat" cancels their RSVP to "Ruby Zagreb Meetup #42"
    And I am signed in as "Ana Kovač"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see "Going (3)" followed by "Iva Babić, Luka Perić and Sara Novak"
    And I should see "Waitlist (0)"

  @ac-4
  Scenario: A signed-in person who is not the organizer sees no names
    Given I am signed in as "Marko Horvat"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see no attendee lists
    And I should not see "Iva Babić"
    And I should not see "Luka Perić"
    And I should not see "Sara Novak"

  @ac-5
  Scenario: A guest sees no attendee lists
    Given I am not signed in
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see no attendee lists
    And I should not see "Marko Horvat"

  @ac-6
  Scenario Outline: No email address appears on the event page
    Given I am signed in as "<person>"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see no email addresses

    Examples:
      | person       |
      | Ana Kovač    |
      | Marko Horvat |

  @ac-7
  Scenario: The organizer's list has no remove or reorder controls
    Given I am signed in as "Ana Kovač"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see no controls to remove or reorder people
