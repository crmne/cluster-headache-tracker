import { Controller } from "@hotwired/stimulus"
import { formatDate, formatTime } from "i18n"

export default class extends Controller {
  static targets = ["field", "ongoingBadge", "readout"]
  static values = { setNowOnConnect: Boolean }

  connect() {
    if (this.setNowOnConnectValue && !this.fieldTarget.value) {
      this.setNow();
    }

    // Show/hide ongoing badge based on initial end time value
    if (this.hasOngoingBadgeTarget) {
      this.toggleOngoingBadge(this.fieldTarget.value)
    }

    this.updateReadout(this.fieldTarget.value)
  }

  setNow(event) {
    if (event) {
      event.preventDefault();
    }

    // Get current date in local timezone
    const now = new Date();

    // Format date to local ISO string
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');

    // Create the datetime-local format (YYYY-MM-DDThh:mm)
    const formattedDate = `${year}-${month}-${day}T${hours}:${minutes}`;
    this.fieldTarget.value = formattedDate;

    // Update ongoing badge if this is the end time field
    if (this.hasOngoingBadgeTarget) {
      this.toggleOngoingBadge(formattedDate)
    }

    this.updateReadout(formattedDate)
  }

  // Called when the time changes
  timeChanged(event) {
    if (this.hasOngoingBadgeTarget) {
      this.toggleOngoingBadge(event.target.value)
    }

    this.updateReadout(event.target.value)
  }

  toggleOngoingBadge(value) {
    this.ongoingBadgeTarget.classList.toggle('hidden', value !== '')
  }

  // Shows the chosen time in the user's language and 12h/24h preference,
  // since native datetime pickers follow the device's own settings
  updateReadout(value) {
    if (!this.hasReadoutTarget) return

    const date = value ? new Date(value) : null

    if (date && !isNaN(date)) {
      const day = formatDate(date, { weekday: "short", day: "numeric", month: "short" })
      this.readoutTarget.textContent = `${day} · ${formatTime(date)}`
    } else {
      this.readoutTarget.textContent = ""
    }
  }
}
