// app/javascript/controllers/timer_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    start: String
  }

  static targets = [
    'days', 'hours', 'minutes', 'seconds',
    'daysContainer', 'hoursContainer', 'minutesContainer', 'secondsContainer'
  ]

  connect() {
    this.updateTimer()
    this.timerInterval = setInterval(() => this.updateTimer(), 1000)
  }

  disconnect() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }
  }

  updateTimer() {
    const startTime = new Date(this.startValue)
    const now = new Date()
    const diffInSeconds = Math.floor((now - startTime) / 1000)

    const days = Math.floor(diffInSeconds / (3600 * 24))
    const hours = Math.floor((diffInSeconds % (3600 * 24)) / 3600)
    const minutes = Math.floor((diffInSeconds % 3600) / 60)
    const seconds = diffInSeconds % 60

    // Update values and visibility
    this.updateValue('days', days)
    this.updateValue('hours', hours)
    this.updateValue('minutes', minutes)
    this.updateValue('seconds', seconds)
  }

  updateValue(unit, value) {
    const container = this[`${unit}ContainerTarget`]
    const element = this[`${unit}Target`]

    // Show/hide the container based on the value
    container.classList.toggle('hidden', value === 0)

    // Update the countdown value
    element.style.setProperty('--value', value)
  }
}
