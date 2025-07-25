// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { initializeCharts } from "headache_charts"
import { Turbo } from "@hotwired/turbo-rails"

// Add redirect action for Turbo Streams
Turbo.StreamActions.redirect = function() {
  const url = this.templateContent.textContent.trim()
  Turbo.visit(url)
}

if (typeof window.initializeCharts == "undefined") {
  window.initializeCharts = initializeCharts;
}

// Reinitialize charts after Turbo frame updates
document.addEventListener('turbo:frame-render', function(event) {
  const frame = event.target;
  if (frame.id === 'charts') {
    console.log('Charts frame updated, reinitializing...');
    // Give Stimulus time to connect controllers
    setTimeout(() => {
      const chartsElement = frame.querySelector('[data-controller="charts"]');
      if (chartsElement) {
        // Trigger a reconnect by updating a data attribute
        chartsElement.setAttribute('data-charts-reinitialized', Date.now());
      }
    }, 100);
  }
});
