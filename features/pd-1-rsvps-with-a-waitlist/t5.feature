@pd-1-t5
Feature: Seats left on the events index
  The events listing shows how many seats each upcoming event has left,
  so people can tell which events are filling up before opening them.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 3 seats

  @ac-1
  Scenario: An event nobody has RSVPed to shows every seat left
    When I visit the events page
    Then I should see "3 of 3 seats left"

  @ac-2
  Scenario: An RSVP takes a seat
    Given "Marko Horvat" has RSVPed to "Ruby Zagreb Meetup #42"
    When I visit the events page
    Then I should see "2 of 3 seats left"

  @ac-3
  Scenario: An event with every seat taken shows Full
    Given "Marko Horvat, Iva Babić and Luka Perić" RSVP to "Ruby Zagreb Meetup #42" in turn
    When I visit the events page
    Then I should see "Full"
    And I should not see "seats left"

  @ac-4
  Scenario: Waitlisted RSVPs do not take seats
    Given "Marko Horvat" has RSVPed to "Ruby Zagreb Meetup #42"
    And "Iva Babić" is on the waitlist for "Ruby Zagreb Meetup #42"
    When I visit the events page
    Then I should see "2 of 3 seats left"

  @ac-5
  Scenario: Lowering capacity below the going count shows Full, never a negative number
    Given "Marko Horvat, Iva Babić and Luka Perić" RSVP to "Ruby Zagreb Meetup #42" in turn
    And the capacity of "Ruby Zagreb Meetup #42" is lowered to 1
    When I visit the events page
    Then I should see "Full"
    And I should not see "-2"

  @ac-6
  Scenario: The events page counts seats for every event in a single query
    Given "Ana Kovač" organizes "Rails Workshop" with 2 seats
    And "Ana Kovač" organizes "Hotwire Night" with 5 seats
    And "Marko Horvat" has RSVPed to "Ruby Zagreb Meetup #42"
    And "Iva Babić" has RSVPed to "Rails Workshop"
    When I visit the events page while counting queries
    Then I should see "2 of 3 seats left"
    And I should see "1 of 2 seats left"
    And I should see "5 of 5 seats left"
    And 1 query ran against rsvps
