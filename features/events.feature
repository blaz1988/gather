Feature: Browsing events
  Anyone can see upcoming events; only organizers change them.

  Background:
    Given "Ana Kovač" organizes "Ruby Zagreb Meetup #42" with 3 seats

  Scenario: A guest browses upcoming events
    Given I am not signed in
    When I visit the events page
    Then I should see "Ruby Zagreb Meetup #42"
    And I should see "Organized by Ana Kovač · 3 of 3 seats left"

  Scenario: The organizer sees an edit link
    Given I am signed in as "Ana Kovač"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should see "Edit event"

  Scenario: Someone else doesn't
    Given I am signed in as "Marko Horvat"
    When I open the event "Ruby Zagreb Meetup #42"
    Then I should not see "Edit event"
