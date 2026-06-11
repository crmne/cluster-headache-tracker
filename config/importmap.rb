# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@hotwired/hotwire-native-bridge", to: "@hotwired--hotwire-native-bridge.js" # @1.0.0
pin_all_from "app/javascript/controllers", under: "controllers"

# Chart.js and dependencies, vendored as self-contained ESM bundles
pin "chart.js" # @4.4.6
pin "chartjs-adapter-date-fns" # @3.0.0
pin "date-fns" # @2.30.0
