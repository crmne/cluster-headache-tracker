import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "ongoingBadge"]

  connect() {
    // Only set initial time if this is a new record
    if (!this.fieldTarget.value && window.location.pathname.match(/\/new$/)) {
      // Only set initial time for start_time field, not end_time
      if (this.fieldTarget.name === "headache_log[start_time]") {
        this.setNow();
      }
    }

    // Show/hide ongoing badge based on initial end time value
    if (this.hasOngoingBadgeTarget) {
      this.toggleOngoingBadge(this.fieldTarget.value)
    }
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
