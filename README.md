# 🧠 Cluster Headache Tracker

Cluster Headache Tracker is a free, open-source web application designed to help individuals suffering from cluster headaches track and manage their condition. By providing detailed logging, visual insights, and easy sharing with healthcare providers, this tool aims to improve the understanding and treatment of cluster headaches.

## 💝 Support the Project

If you find Cluster Headache Tracker helpful in managing your condition, please consider supporting its development:

[![Sponsor on GitHub](https://img.shields.io/github/sponsors/crmne?label=Sponsor&logo=github)](https://github.com/sponsors/crmne)

Your support helps keep this tool free and continuously improving for the cluster headache community.

## 🎥 Demo

[![Cluster Headache Tracker Demo](https://img.youtube.com/vi/4HlsqANZdv8/maxresdefault.jpg)](https://youtu.be/4HlsqANZdv8)

## 🚀 Getting Started

Visit [https://clusterheadachetracker.com](https://clusterheadachetracker.com) to create a free account and start tracking your cluster headaches.

## 📱 Mobile Apps

### iOS App (Beta)
We have a beta version of our iOS app available through TestFlight! This native app provides the best possible experience for iOS users.
- [Download the iOS Beta App](https://testflight.apple.com/join/GJsAQqz2)
- [Contribute to the iOS Beta App](https://github.com/crmne/cluster-headache-tracker-ios)

### Android App (Beta)
The Beta Android app is available for direct download from our website:
- [Download the Android Beta App](https://clusterheadachetracker.com/cluster-headache-tracker.apk?v=1.0.11)
- [Contribute to the Android Beta App](https://github.com/crmne/cluster-headache-tracker-android)

Both apps provide the same features as the web application in a native mobile interface:
- Quick logging during attacks
- Automatic time filling
- Real-time attack duration tracking
- Charts and statistics
- Easy sharing with doctors

## ✨ Features

- 📝 **Smart Logging**: Auto-fills current time, just slide for intensity during attacks
- ⏱️ **Attack Tracking**: Real-time duration timer for ongoing attacks
- 📊 **Visual Insights**: Interactive charts showing attack patterns and predicting cluster period endings
- 🩺 **Doctor's View**: Generate shareable reports that have helped many users get oxygen therapy approved
- 💾 **Data Import/Export**: Easy CSV import/export for backup or analysis
- 🔒 **Secure & Private**: Encrypted data stored in Germany, no email required
- 🇪🇺 **EU-Based**: Full compliance with strict EU data protection regulations
- 📱 **Native Apps**: Dedicated apps for iOS and Android
- 🌟 **Open Source**: Free forever, community-driven development

## 💻 Development Setup

### Prerequisites

- Ruby 3.4.2
- PostgreSQL
- Node.js

### Setup Instructions

1. Clone the repository:
   ```
   git clone https://github.com/crmne/cluster-headache-tracker.git
   cd cluster-headache-tracker
   ```

2. Install dependencies:
   ```
   bundle install
   npm install
   ```

3. Set up environment variables:
   Create a `.env` file in the root directory and add the following variables:
   ```
   RAILS_MASTER_KEY=your_master_key
   POSTGRES_PASSWORD=your_database_password
   HONEYBADGER_API_KEY=your_honeybadger_api_key
   ```

4. Provision the local PostgreSQL role:
   ```
   bin/rails db:setup_roles
   ```
   This creates the `cluster_headache_tracker` role plus the development and test databases using `POSTGRES_PASSWORD` from your environment or `.env`.

   If you prefer a simpler manual fallback, use:
   ```
   ./bin/pg_add_user.sh cluster_headache_tracker
   ```

5. Set up the database:
   ```
   bin/rails db:prepare
   ```

6. Start the development server:
   ```
   bin/dev
   ```

7. Visit `http://localhost:3000` in your browser to see the application running locally.

## 🧪 Running Tests

To run the test suite:

```
rails test
rails test:system
```

## 🚢 Deployment

This project uses Kamal for deployment. To deploy:

1. Set up your deployment configuration in `config/deploy.yml`.
2. Run:
   ```
   kamal deploy
   ```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for more details on how to get started.

## 📄 License

Cluster Headache Tracker is released under the [GNU General Public License v3.0 (GPL-3.0)](LICENSE).

## 🔒 Privacy

We take your privacy seriously. Cluster Headache Tracker does not collect or store any personally identifiable information. Users are identified by a username only, not an email address. All data is stored on servers located in Germany, ensuring compliance with strict EU data protection regulations.

## 🆘 Support

If you encounter any issues or have questions, please [open an issue](https://github.com/crmne/cluster_headache_tracker/issues) on GitHub.

## 🙏 Acknowledgements

Thank you to all the contributors and users who help make this project better every day.
