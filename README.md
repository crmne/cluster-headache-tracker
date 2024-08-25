# 🧠 Cluster Headache Tracker

Cluster Headache Tracker is a free, open-source web application designed to help individuals suffering from cluster headaches track and manage their condition. By providing detailed logging, visual insights, and easy sharing with healthcare providers, this tool aims to improve the understanding and treatment of cluster headaches.

## 🎥 Demo

https://github.com/user-attachments/assets/75b4bd2b-b539-4d44-90ad-c3c03148daed

## ✨ Features

- 📝 **Detailed Logging**: Record intensity, duration, triggers, and medications for each headache episode.
- 📊 **Visual Insights**: Gain valuable insights with interactive charts and graphs showing your headache patterns over time.
- 🩺 **Share with Doctors**: Generate shareable reports to collaborate effectively with your healthcare providers.
- 💾 **Data Import/Export**: Easily import and export your headache logs in CSV format for backup or analysis.
- 🔒 **Secure & Private**: Your health data is encrypted and stored securely, with full control over sharing.
- 🕵️ **Privacy-Focused**: We don't store any personally identifiable information. Users are identified by a username, not an email address.
- 🇪🇺 **EU-Based**: Our servers are hosted in Germany, ensuring compliance with strict EU data protection regulations.
- 📱 **Mobile Friendly**: Access your tracker on any device with our responsive, mobile-friendly design.
- 🌟 **Open Source**: Contribute to the development and customize the tracker to fit your needs.

## 🚀 Getting Started

Visit [https://clusterheadachetracker.com](https://clusterheadachetracker.com) to create a free account and start tracking your cluster headaches.

## 💻 Development Setup

### Prerequisites

- Ruby 3.3.4
- PostgreSQL

### Setup Instructions

1. Clone the repository:
   ```
   git clone https://github.com/crmne/cluster-headache-tracker.git
   cd cluster-headache-tracker
   ```

2. Install dependencies:
   ```
   bundle install
   ```

3. Set up the database:
   ```
   rails db:create
   rails db:migrate
   ```

4. Set up environment variables:
   Create a `.env` file in the root directory and add the following variables:
   ```
   RAILS_MASTER_KEY=your_master_key
   POSTGRES_PASSWORD=your_database_password
   HONEYBADGER_API_KEY=your_honeybadger_api_key
   ```

5. Start the development server:
   ```
   bin/dev
   ```

6. Visit `http://localhost:3000` in your browser to see the application running locally.

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

## 🍕 Support the Project

If you find this tool valuable, please consider making a donation:

[![Buy me a pizza](app/assets/images/buymeapizza.png)](https://buymeacoffee.com/crmne)

## 🆘 Support

If you encounter any issues or have questions, please [open an issue](https://github.com/crmne/cluster_headache_tracker/issues) on GitHub.

## 🙏 Acknowledgements

Thank you to all the contributors and users who help make this project better every day.
