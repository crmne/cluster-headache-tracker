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

### Native Apps

The iOS ([crmne/cluster-headache-tracker-ios](https://github.com/crmne/cluster-headache-tracker-ios)) and Android ([crmne/cluster-headache-tracker-android](https://github.com/crmne/cluster-headache-tracker-android)) apps are Hotwire Native shells around these pages. What they rely on is a contract: change a bridge component's name, events or payload keys, a path in `public/configurations/*_v2.json`, or the user agent on both sides together, and keep the apps' bundled path configurations identical to the server's.

- User agent: `ClusterHeadacheTracker; platform=ios|android; version=X.Y.Z; build=N;`, plus `store=play` from Android builds Google Play installed. `ios_native_app?`, `android_native_app?`, `native_app_version`, `native_app_store`.
- Store builds (every iOS build, and Android with `store=play`) update through their store: `mobile_app_from_store?` keeps them from hearing about GitHub releases (Google Play forbids pointing at other downloads) and sends required updates to `AppConstants::IOS_APP_STORE_URL` or `PLAY_STORE_URL`. Only GitHub APK installs are offered the APK.
- `widget-status`: signed-in pages send `connect` with `{ ongoing, startedAt, lastAttackAt, attackFreeDays, attacksToday, locale }`; signed-out pages send `clear`, so widgets, shortcuts and the Live Activity forget the last account after signing out elsewhere, an expired session or a deleted account.
- Account deletion is in Settings for the apps too (`Users::AccountsController`, password required, native destructive alert), as both stores require; `/delete-account` explains it publicly for Google Play's deletion URL.
- Store review uses a synthetic account: `DEMO_PASSWORD=... bin/rails demo:reset` (`DemoAccount`, username `appreview` by default) replaces its history with a made-up cluster period ending today. It refuses any account holding logs it didn't write. Reset it before each submission; reviewers may delete it.

### Sharing, Import, and Export

- CSV export is handled by `HeadacheLog.to_csv` and `HeadacheLogExportsController`
- CSV import is handled by `HeadacheLog.import_csv` and `HeadacheLogImportsController`. It detects Migraine Buddy exports (`HeadacheLog::MigraineBuddyExport`), skips attacks already logged at the same start time, and returns a `HeadacheLog::ImportResult` with the detected format and imported/skipped counts
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
- Production errors go to our self-hosted Bugsink at https://errors.paolino.me (Hetzner, Germany), project `cluster-headache-tracker-production`, through the Sentry SDK (`config/initializers/sentry.rb`). The DSN is `sentry_dsn` in Rails credentials (`SENTRY_DSN` overrides it). Reports name the user by id only, collect no request bodies, query strings, cookies, or IP addresses, go through `filter_parameters`, and send no traces. Never set `send_default_pii`.

### Primary Keys

- Default Rails integer / bigint primary keys

## Testing Reference

- Standard Rails Minitest suite with `fixtures :all`
- `ActiveSupport::TestCase` includes Devise and Warden helpers in `test/test_helper.rb`
- System tests use Selenium with headless Chrome via `ApplicationSystemTestCase`
- System tests assert client-side JavaScript error tracking stays clean after each test
- Current coverage centers on headache logs, charts, shared logs, feedback, mailers, and the core user model

<!-- github-automation: pull-requests -->
## Pull requests

This section is maintained account-wide by
[crmne/github-automation](https://github.com/crmne/github-automation) and is
replaced when that policy changes. Do not edit it here. If it does not fit this
repository, say so in a review or issue, and put repository-specific rules in a
separate section, which takes precedence.

Review evidence stays out of the repository. Before-and-after screenshots,
captures, comparison pages, recordings, and anything else made to show
reviewers a change go in the pull request description or its comments: attach
the files there, or link a page published elsewhere. Only media the project
itself uses, such as documentation figures, release-note images, and app
assets, belongs in the repository.

Dependencies come from their package registry, such as crates.io, RubyGems, or
npm, or from repositories the maintainer controls, under `github.com/crmne/`
or this repository's own organization. A git dependency, or a patch, override,
or replace entry, may point only at such a repository, and adding or changing
one needs the maintainer's explicit approval. Never point a dependency at a
contributor's fork or any other source the maintainer does not control. When a
dependency needs a fix, send it upstream and ask the maintainer to carry it in
a fork they control until a release includes it.

Reviewers treat either problem in a pull request as a blocker.
<!-- /github-automation: pull-requests -->
