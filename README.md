<div align="center">
  <img src="app/assets/images/logo_small@2x.png" alt="Cluster Headache Tracker" width="96" height="96">

  <h1>Cluster Headache Tracker</h1>

  <p><strong>Fast cluster headache logging, useful charts, and shareable reports.</strong></p>

  <p>Built by someone with cluster headaches who wanted a better tool.</p>

  <p>
    <a href="https://github.com/crmne/cluster-headache-tracker/actions/workflows/ci-main.yml"><img src="https://github.com/crmne/cluster-headache-tracker/actions/workflows/ci-main.yml/badge.svg?branch=main" alt="CI"></a>
    <a href="LICENSE"><img src="https://img.shields.io/github/license/crmne/cluster-headache-tracker" alt="License"></a>
    <a href="https://github.com/sponsors/crmne"><img src="https://img.shields.io/github/sponsors/crmne?label=Sponsor&logo=github" alt="Sponsor"></a>
  </p>
</div>

---

Cluster Headache Tracker is an open source Rails app for logging attacks, reviewing patterns over time, and sharing data with doctors.

The public app lives at [clusterheadachetracker.com](https://clusterheadachetracker.com). This repository contains the web application behind it.

## Why it exists

This project was built to make tracking cluster headaches less frustrating:

- fast attack logging
- charts based on the same data you enter day to day
- CSV import and export
- expiring share links for doctors or family
- username-based accounts instead of email-based signup

The app is privacy-focused, runs in Germany, and is available on the web, as a PWA, and through native mobile shells.

## Demo

[![Watch the demo](https://img.youtube.com/vi/4HlsqANZdv8/maxresdefault.jpg)](https://youtu.be/4HlsqANZdv8)

If you want to see the product before running it locally, start there.

## Mobile apps

### iOS

- [Install the beta on TestFlight](https://testflight.apple.com/join/GJsAQqz2)
- [iOS source code](https://github.com/crmne/cluster-headache-tracker-ios)

### Android

- [Download the beta APK](https://clusterheadachetracker.com/cluster-headache-tracker.apk?v=1.0.11)
- [Android source code](https://github.com/crmne/cluster-headache-tracker-android)

## Running locally

Prerequisites:

- Ruby 3.4.2
- PostgreSQL
- Node.js

Clone the repository and install dependencies:

```bash
git clone https://github.com/crmne/cluster-headache-tracker.git
cd cluster-headache-tracker
bundle install
npm install
```

Create a `.env` file with the values you need locally:

```bash
RAILS_MASTER_KEY=...
POSTGRES_PASSWORD=...
HONEYBADGER_API_KEY=...
```

Set up PostgreSQL:

```bash
bin/rails db:setup_roles
```

That creates the `cluster_headache_tracker` role plus the development and test databases using `POSTGRES_PASSWORD` from your environment.

If you prefer the older manual fallback:

```bash
./bin/pg_add_user.sh cluster_headache_tracker
```

Install the repo hook and boot the app:

```bash
bin/setup-git-hooks
bin/setup
```

`bin/setup` installs gems if needed, prepares the database, clears old logs and temp files, and then starts `bin/dev`.

The app runs at `http://localhost:3000`.

If you want a local seeded user, set `SEED_USER_USERNAME` and `SEED_USER_PASSWORD` and run:

```bash
bin/rails db:seed
```

## Tests and CI

For normal development:

```bash
bin/rails test
bin/rails test:system
```

For the full local CI pipeline:

```bash
bin/ci
```

`bin/ci` runs setup, linting, security checks, migration checks, the test suite, and system tests. The pre-push hook installed by `bin/setup-git-hooks` runs it automatically before pushes.

## Deployment

Deploys are tag-driven.

Create a release tag from `origin/main` with:

```bash
script/release 1.0.11
```

That pushes an annotated `v1.0.11` tag. GitHub Actions then deploys that tag to production with Kamal and creates a GitHub Release.

Pushes to `main` do not deploy production.

If you need to deploy manually:

```bash
bundle exec kamal deploy
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Support

Bug reports and feature requests are welcome in [GitHub Issues](https://github.com/crmne/cluster-headache-tracker/issues).

If the app is useful to you, you can support development here:

[GitHub Sponsors](https://github.com/sponsors/crmne)

## License

Released under the [GNU General Public License v3.0](LICENSE).
