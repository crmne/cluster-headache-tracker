# Cluster Headache Tracker

## What is Cluster Headache Tracker?

Cluster Headache Tracker is a privacy-focused Rails app for people with cluster headaches to log attacks, spot patterns, share reports, and use the app from the web, PWA, and native mobile shells. The product deliberately avoids email-based identity in favor of username/password accounts and keeps the core flows fast enough to use during an attack.

`CLAUDE.md` is only a compatibility shim that points here. Please read the separate file `STYLE.md` for coding style guidance.

## Development Commands

### Setup and Server
```bash
bin/setup                  # Install gems, prepare the DB, clear tmp/logs, then start bin/dev
bin/setup --skip-server    # Same setup flow without launching the dev server
bin/setup-git-hooks        # Configure .githooks/pre-push to run bundle exec bin/ci
bin/dev                    # Start the Rails server plus frontend watchers
```

Development URL: http://localhost:3000

If you want a local seeded account, set `SEED_USER_USERNAME` and `SEED_USER_PASSWORD` before running `bin/rails db:seed`.

### Testing
```bash
bin/rails test                              # Fast unit/controller/model tests
bin/rails test test/models/user_test.rb    # Single test file
bin/rails test:system                      # Capybara + headless Chrome
bin/ci                                     # Full local CI pipeline
```

CI pipeline (`bin/ci`) runs:
1. Setup (`bin/setup --skip-server`)
2. `bundle check`
3. Rubocop
4. Bundler audit
5. Importmap audit
6. Brakeman
7. Flay
8. Pending-migration check
9. Rails tests
10. System tests

### Database
```bash
bin/rails db:prepare       # Create/migrate local DBs
bin/rails db:setup_roles   # Provision the local PostgreSQL role and databases
bin/rails db:migrate       # Run migrations
bin/rails db:reset         # Drop, create, migrate, seed
bin/rails db:seed          # Seed the optional local user
```

### Release and Deploy
```bash
script/release 1.0.11      # Create and push an annotated v1.0.11 tag from origin/main
bundle exec kamal deploy   # Manual deploy
```

Production deploys are tag-driven. Pushing to `main` runs CI, but production release happens from `v*` tags through GitHub Actions.

### Migrations

- Always create migrations with Rails generators so timestamps, naming, and boilerplate stay consistent.
- Treat `db/schema.rb` as generated state, not a hand-edited file.

## Architecture Overview

### User Model and Authentication

This app is user-scoped and intentionally simple:

- `User` authenticates with Devise using username/password.
- `email_required?` is disabled, so email is not part of the product model.
- Admin access is currently a simple username check: `current_user.admin?` is true only for `username == "carmine"`.
- Custom Devise controllers redirect native-app logins back into the Hotwire Native flow.

### Core Domain Models

**User**
- Owns `headache_logs`, `share_tokens`, and one `feedback_survey`
- Sends an admin notification after signup
- Tracks changelog and welcome-modal acknowledgement state

**HeadacheLog**
- Central tracking entity with start/end times, intensity, medication, triggers, and notes
- Supports filtering, chart aggregation, CSV export, and CSV import
- Broadcasts create/update/destroy changes through Turbo Streams so the dashboard, charts, and ongoing-attack UI stay live

**ShareToken**
- Generates time-limited public sharing links for a user's logs
- Tokens expire after 30 days

**FeedbackSurvey**
- One survey per user
- Stores product feedback, platform usage, doctor-sharing data, and feature preferences

### Request Flow and UI

- `HeadacheLogsController` is the main signed-in CRUD surface.
- `ChartsController` uses `HeadacheLog.chart_data` to render aggregate views from the same filtered dataset.
- `SharedLogsController` exposes a token-based read-only view into a user's logs and charts.
- `FeedbackController` prevents duplicate survey submission and emails admins when new feedback arrives.
- `Admin::UsersController` and `Admin::FeedbackSurveysController` handle operational/admin tasks.

### Frontend Stack

- Rails 8.1 with Turbo, Stimulus, importmap, and Tailwind CSS 4
- DaisyUI for component styling
- Chart rendering is driven by the server-generated chart payloads plus client-side JavaScript in `app/javascript/headache_charts.js`
- PWA assets live under `app/views/pwa`
- Native app behavior is detected via user agent helpers and version parsing in `ApplicationHelper`

### Sharing, Import, and Export

- CSV export is handled by `HeadacheLog.to_csv` and `HeadacheLogExportsController`
- CSV import is handled by `HeadacheLog.import_csv` and `HeadacheLogImportsController`
- Share links are modeled as a separate resource (`resource :share_link`) instead of custom actions on logs

### Background Work and Notifications

- `AdminNotificationsMailer` sends new-user and new-feedback notifications
- `SitemapRefreshJob` regenerates the sitemap
- The app includes the Solid Queue / Solid Cache / Solid Cable stack from modern Rails defaults

### Security and Privacy

- Authentication is required for all personal data flows
- Shared links are token-based and expire
- `rack-attack` is enabled
- Data is scoped per user, with no multi-account tenancy layer

### Primary Keys

- Default Rails integer / bigint primary keys

## Testing Reference

- Standard Rails Minitest suite with `fixtures :all`
- `ActiveSupport::TestCase` includes Devise and Warden helpers in `test/test_helper.rb`
- System tests use Selenium with headless Chrome via `ApplicationSystemTestCase`
- System tests assert client-side JavaScript error tracking stays clean after each test
- Current coverage centers on headache logs, charts, shared logs, feedback, mailers, and the core user model
