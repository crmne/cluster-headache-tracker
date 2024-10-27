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
    // Parse the ISO string from data-timer-start-value
    const startTime = new Date(this.startValue)
    const now = new Date()

    // Calculate difference in seconds, ensuring positive value
    const diffInSeconds = Math.max(0, Math.floor((now - startTime) / 1000))

    // Calculate all time units
    const days = Math.floor(diffInSeconds / (24 * 60 * 60))
    const hours = Math.floor((diffInSeconds % (24 * 60 * 60)) / (60 * 60))
    const minutes = Math.floor((diffInSeconds % (60 * 60)) / 60)
    const seconds = diffInSeconds % 60

    // Always show all units when there's an active timer
    this.daysContainerTarget.classList.remove('hidden')
    this.hoursContainerTarget.classList.remove('hidden')
    this.minutesContainerTarget.classList.remove('hidden')
    this.secondsContainerTarget.classList.remove('hidden')

    // Set the values
    this.daysTarget.style.setProperty('--value', days)
    this.hoursTarget.style.setProperty('--value', hours)
    this.minutesTarget.style.setProperty('--value', minutes)
    this.secondsTarget.style.setProperty('--value', seconds)
  }
}
