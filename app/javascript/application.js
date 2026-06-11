// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { initializeCharts } from "headache_charts"

// Initialize Hotwire Native Bridge if available
import("@hotwired/hotwire-native-bridge").then(({ Bridge }) => {
  window.Hotwire = window.Hotwire || {}
  window.Hotwire.bridge = Bridge
  Bridge.start()
}).catch(() => {
  // Bridge not available in web browser, that's ok
})

if (typeof window.initializeCharts == "undefined") {
  window.initializeCharts = initializeCharts;
}
