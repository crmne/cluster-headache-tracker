// app/javascript/controllers/time_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "ongoingBadge"]

  connect() {
    // Show/hide ongoing badge based on initial end time value
    if (this.hasOngoingBadgeTarget) {
      this.toggleOngoingBadge(this.fieldTarget.value)
    }
  }

  setNow(event) {
    event.preventDefault()
    const now = new Date()
    const formattedDate = now.toISOString().slice(0, 16) // Format as YYYY-MM-DDTHH:mm
    this.fieldTarget.value = formattedDate

    // Update ongoing badge if this is the end time field
    if (this.hasOngoingBadgeTarget) {
      this.toggleOngoingBadge(formattedDate)
    }
  }

  // Called when end time changes
  timeChanged(event) {
    if (this.hasOngoingBadgeTarget) {
      this.toggleOngoingBadge(event.target.value)
    }
  }

  toggleOngoingBadge(value) {
    this.ongoingBadgeTarget.classList.toggle('hidden', value !== '')
  }
}
