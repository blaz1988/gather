# Gather

A small Rails 8.1 app for community events, used to demonstrate
[plan_driven](https://github.com/blaz1988/plan-driven): an implementation plan, tickets,
one Cursor cloud agent and pull request per ticket, and Cucumber evidence for every
acceptance criterion.

## Run it

```sh
bin/setup          # installs gems, prepares the database and seeds demo data
bin/rails server
```

Sign in as `ana@gather.test`, `marko@gather.test` or `ivan@gather.test` (password `password123`).

## Tests

```sh
bin/rubocop
bundle exec rspec
bundle exec cucumber
```

CI runs all three on every pull request.

## Plans

Implementation plans and delivery reports live in [`docs/plans`](docs/plans).

```sh
bin/plan-driven doctor
bin/plan-driven new "Title of the change"
```
