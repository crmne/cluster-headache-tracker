# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Deps: Bundle check", "bundle check"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit check --update"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Security: Flay duplication scan", "bundle exec flay app config db lib test"

  step "DB: Pending migrations", "bin/rails db:abort_if_pending_migrations"

  step "Tests: Rails", "bin/rails test"
  step "Tests: System", "bin/rails test:system"
end
