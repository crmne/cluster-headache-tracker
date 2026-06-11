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

  // Stimulus fires these once on connect and again whenever a value changes
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