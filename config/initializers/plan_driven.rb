# Keys are never set here. They come from the environment or ~/.plan_driven/config,
# written by `bin/plan-driven configure`.
if defined?(PlanDriven)
  PlanDriven.configure do |config|
    # Plans and tickets are drafted by Claude Opus 5.5 on our Cursor account. It reads this
    # codebase (read-only) while it writes.
    config.llm_provider = :cursor
    config.llm_model = "claude-opus-5-5"
    config.request_timeout = 600

    config.plan_approvals = %w[review]
    config.ticket_approvals = %w[review]

    # One Cursor cloud agent, and one pull request, per ticket.
    config.agent_model = "claude-opus-5-5"
    config.base_branch = "main"
    config.max_parallel_agents = 3

    config.github_repository = "blaz1988/gather"

    config.team_rules = [
      "Views are ERB and reuse the classes in app/assets/stylesheets/application.css (card, button, " \
      "badge, people, section). Add CSS there only when no class fits.",
      "Authentication is Rails 8's: Current.user, `allow_unauthenticated_access`, `authenticated?` in views.",
      "Keep controllers thin; put a multi-step change in a model method or a PORO in app/models.",
      "Tests are RSpec request and model specs with FactoryBot, and Cucumber features that reuse " \
      "features/step_definitions/common_steps.rb (e.g. `Given I am signed in as \"Ana Kovač\"`).",
      "bin/rubocop, bundle exec rspec and bundle exec cucumber must pass; CI runs all three."
    ]
    config.extra_context = "Gather lists community events. An event has an organizer (a User) and a " \
                           "capacity in seats. Anyone can browse; signing in is needed to act."
  end
end
