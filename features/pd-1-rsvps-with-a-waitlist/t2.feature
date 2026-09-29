@pd-1-t2
Feature: RSVP, cancel, waitlist and promotion rules
  Seats are counted from RSVPs. When an event is full, people join a waitlist,
  and a freed seat goes to the person who has waited longest.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 3 seats

  @ac-1
  Scenario: An event nobody has RSVPed to has every seat left
    Then "Ruby Zagreb Meetup #42" has 3 seats left
    And "Ruby Zagreb Meetup #42" is not full
    And "Ruby Zagreb Meetup #42" has an empty waitlist

  @ac-2
  Scenario: People beyond capacity join the waitlist in turn
    Given "Ana Kovač" organizes "Rails Workshop" with 2 seats
    When "Marko Horvat, Iva Babić, Luka Perić and Sara Novak" RSVP to "Rails Workshop" in turn
    Then "Marko Horvat" is going to "Rails Workshop" with no waitlist position
    And "Iva Babić" is going to "Rails Workshop" with no waitlist position
    And "Luka Perić" is #1 on the waitlist for "Rails Workshop"
    And "Sara Novak" is #2 on the waitlist for "Rails Workshop"

  @ac-3
  Scenario: RSVPing twice changes nothing
    Given "Marko Horvat" has RSVPed to "Ruby Zagreb Meetup #42"
    When "Marko Horvat" RSVPs to "Ruby Zagreb Meetup #42" again
    Then the same RSVP is returned
    And "Ruby Zagreb Meetup #42" has 1 going and 0 waitlisted

  @ac-3
  Scenario: RSVPing twice from the waitlist changes nothing
    Given "Ana Kovač" organizes "Rails Workshop" with 1 seat
    And "Marko Horvat and Iva Babić" RSVP to "Rails Workshop" in turn
    When "Iva Babić" RSVPs to "Rails Workshop" again
    Then the same RSVP is returned
    And "Rails Workshop" has 1 going and 1 waitlisted

  @ac-4 @no-database-cleaner
  Scenario: Several people race for the last seat
    Given "Iva Babić and Luka Perić" RSVP to "Ruby Zagreb Meetup #42" in turn
    When 4 people RSVP to "Ruby Zagreb Meetup #42" at the same time
    Then exactly 1 of them is going and 3 are waitlisted
    And "Ruby Zagreb Meetup #42" has 3 going and 3 waitlisted

  @ac-5
  Scenario: Cancelling a going RSVP promotes only the oldest waitlisted RSVP
    Given "Marko Horvat, Iva Babić, Luka Perić, Sara Novak and Ivan Kos" RSVP to "Ruby Zagreb Meetup #42" in turn
    When "Marko Horvat" cancels their RSVP to "Ruby Zagreb Meetup #42"
    Then "Sara Novak" is going to "Ruby Zagreb Meetup #42" with no waitlist position
    And "Ivan Kos" is #1 on the waitlist for "Ruby Zagreb Meetup #42"
    And "Ruby Zagreb Meetup #42" has 3 going and 1 waitlisted

  @ac-5
  Scenario: Leaving the waitlist promotes nobody and moves the line up
    Given "Marko Horvat, Iva Babić, Luka Perić, Sara Novak, Ivan Kos and Petra Jurić" RSVP to "Ruby Zagreb Meetup #42" in turn
    When "Sara Novak" cancels their RSVP to "Ruby Zagreb Meetup #42"
    Then "Ivan Kos" is #1 on the waitlist for "Ruby Zagreb Meetup #42"
    And "Petra Jurić" is #2 on the waitlist for "Ruby Zagreb Meetup #42"
    And "Ruby Zagreb Meetup #42" has 3 going and 2 waitlisted

  @ac-6
  Scenario: The organizer cannot RSVP to their own event
    When "Ana Kovač" RSVPs to "Ruby Zagreb Meetup #42"
    Then no RSVP is returned
    And there are no RSVPs

  @ac-6
  Scenario: Nobody can RSVP once the event has started
    Given "Ruby Zagreb Meetup #42" started an hour ago
    When "Marko Horvat" RSVPs to "Ruby Zagreb Meetup #42"
    Then no RSVP is returned
    And there are no RSVPs

  @ac-7
  Scenario: Deleting a going person promotes the next waitlisted person
    Given "Marko Horvat, Iva Babić, Luka Perić and Sara Novak" RSVP to "Ruby Zagreb Meetup #42" in turn
    When the person "Marko Horvat" is deleted
    Then "Sara Novak" is going to "Ruby Zagreb Meetup #42" with no waitlist position
    And "Ruby Zagreb Meetup #42" has 3 going and 0 waitlisted

  @ac-7
  Scenario: Deleting an organizer removes their events' RSVPs
    Given "Marko Horvat, Iva Babić, Luka Perić and Sara Novak" RSVP to "Ruby Zagreb Meetup #42" in turn
    When the person "Ana Kovač" is deleted
    Then there are no RSVPs

  @ac-7
  Scenario: Seats left never goes below zero
    Given "Marko Horvat, Iva Babić and Luka Perić" RSVP to "Ruby Zagreb Meetup #42" in turn
    When the capacity of "Ruby Zagreb Meetup #42" is lowered to 1
    Then "Ruby Zagreb Meetup #42" has 0 seats left
    And "Ruby Zagreb Meetup #42" is full
