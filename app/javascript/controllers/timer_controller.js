import { Controller } from "@hotwired/stimulus"
import { t } from "i18n"

export default class extends Controller {
  static values = {
    start: String,
    format: { type: String, default: "long" } // "long" for full timer, "short" for time ago
  }

  static targets = [
    "days", "hours", "minutes", "seconds",  // for full timer
    "daysContainer", "hoursContainer", "minutesContainer", "secondsContainer",
    "timeAgo"  // for time ago display
  ]

  connect() {
    this.updateTimer()
    this.timerInterval = setInterval(() => this.updateTimer(), 1000) // Update every second
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

    if (this.formatValue === "short") {
      this.updateTimeAgo(diffInSeconds)
    } else {
      this.updateFullTimer(diffInSeconds)
    }
  }

  updateTimeAgo(diffInSeconds) {
    if (this.hasTimeAgoTarget) {
      let text
      if (diffInSeconds < 60) {
        text = t("timer.just_now")
      } else if (diffInSeconds < 3600) {
        text = t("timer.minutes", { count: Math.floor(diffInSeconds / 60) })
      } else if (diffInSeconds < 86400) {
        text = t("timer.hours", { count: Math.floor(diffInSeconds / 3600) })
      } else {
        text = t("timer.days", { count: Math.floor(diffInSeconds / 86400) })
      }
      this.timeAgoTarget.textContent = text
    }
  }

  updateFullTimer(diffInSeconds) {
    const days = Math.floor(diffInSeconds / 86400)
    const hours = Math.floor((diffInSeconds % 86400) / 3600)
    const minutes = Math.floor((diffInSeconds % 3600) / 60)
    const seconds = diffInSeconds % 60

    if (this.hasDaysTarget) {
      this.daysTarget.style.setProperty('--value', days)
      this.hoursTarget.style.setProperty('--value', hours)
      this.minutesTarget.style.setProperty('--value', minutes)
      this.secondsTarget.style.setProperty('--value', seconds)

      // Show all units for full timer
      this.daysContainerTarget.classList.remove('hidden')
      this.hoursContainerTarget.classList.remove('hidden')
      this.minutesContainerTarget.classList.remove('hidden')
      this.secondsContainerTarget.classList.remove('hidden')
    }
  }
}
