# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cluster Headache Tracker is a privacy-focused Rails 8.0 web application that helps individuals track and manage cluster headaches. The app emphasizes EU data protection compliance, operates without requiring email addresses, and is deployed in Germany.

## Development Commands

### Running the Application
- `bin/dev` - Start development server (Rails + Tailwind CSS watcher)
- `rails server` - Start Rails server only
- `rails console` - Open Rails console

### Testing
- `rails test` - Run unit and integration tests
- `rails test:system` - Run system tests
- `rails test test/models/user_test.rb` - Run specific test file
- `rails test test/models/user_test.rb:10` - Run test at specific line

### Code Quality
- `rubocop` - Run Ruby linting (auto-corrects on pre-commit)
- `rubocop -a` - Auto-correct Ruby style issues
- `erb_lint` - Lint ERB templates
- `brakeman` - Security analysis (runs on pre-push)

### Database
- `rails db:migrate` - Run pending migrations
- `rails db:rollback` - Rollback last migration
- `rails db:seed` - Seed database with sample data

### Deployment
- `kamal deploy` - Deploy to production
- `rails assets:precompile` - Compile assets for production

## Architecture

### Key Models
- **User** - Username-based authentication (no email), uses Devise
- **HeadacheLog** - Core tracking entity with intensity, duration, notes
- **ShareToken** - Enables secure sharing of logs with healthcare providers

### Frontend Stack
- **Tailwind CSS 4.0** with DaisyUI components
- **Stimulus.js** for JavaScript behavior
- **Turbo** for SPA-like navigation
- **Importmap** for JavaScript module management (no webpack/bundler)

### Privacy & Security
- No personal data collection beyond username
- EU-based deployment (Germany)
- Rack-attack for request throttling
- Encrypted credentials using Rails master key
- Share tokens for secure, temporary access to logs

### Key Features Implementation
- **CSV Import/Export**: app/controllers/headache_logs_controller.rb (import/export actions)
- **Charts**: app/views/headache_logs/charts.html.erb with Chart.js
- **PWA Support**: public/manifest.json and service worker configuration
- **Real-time Attack Tracking**: Stimulus controllers in app/javascript/controllers/

### Development Environment
- Uses Overcommit for Git hooks (runs tests, linting automatically)
- Honeybadger for error tracking
- PostgreSQL for database
- Ruby 3.4.2 with Rails 8.0.0

### Testing Approach
- Minitest for unit/integration tests
- System tests use Capybara with headless Chrome
- Tests run automatically on pre-push via Overcommit