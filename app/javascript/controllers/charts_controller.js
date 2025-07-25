import { Controller } from "@hotwired/stimulus"
import { initializeCharts } from "headache_charts"

// Connects to data-controller="charts"
export default class extends Controller {
  static values = {
    intensity: Array,
    trigger: Object,
    medication: Object,
    hourly: Array,
    attacksPerDay: Array,
    duration: Array
  }

  connect() {
    // Initialize charts when the controller connects
    this.initializeAllCharts()

    // Also reinitialize when any value changes
    this.observer = new MutationObserver((mutations) => {
      this.initializeAllCharts()
    })

    // Observe attribute changes on this element
    this.observer.observe(this.element, {
      attributes: true,
      attributeFilter: [
        'data-charts-intensity-value',
        'data-charts-trigger-value',
        'data-charts-medication-value',
        'data-charts-hourly-value',
        'data-charts-attacks-per-day-value',
        'data-charts-duration-value'
      ]
    })
  }

  disconnect() {
    // Clean up observer
    if (this.observer) {
      this.observer.disconnect()
    }
    // Charts are automatically cleaned up by the initializeCharts function
  }

  // Also reinitialize when values change
  intensityValueChanged() {
    this.initializeAllCharts()
  }

  triggerValueChanged() {
    this.initializeAllCharts()
  }

  medicationValueChanged() {
    this.initializeAllCharts()
  }

  hourlyValueChanged() {
    this.initializeAllCharts()
  }

  attacksPerDayValueChanged() {
    this.initializeAllCharts()
  }

  durationValueChanged() {
    this.initializeAllCharts()
  }

  initializeAllCharts() {
    // Use requestAnimationFrame to ensure the DOM is ready
    requestAnimationFrame(() => {
      initializeCharts(
        this.intensityValue,
        this.triggerValue,
        this.medicationValue,
        this.hourlyValue,
        this.attacksPerDayValue,
        this.durationValue
      )
    })
  }
}