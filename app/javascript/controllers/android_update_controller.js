import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Check when the modal was last dismissed
    const lastDismissed = localStorage.getItem('androidUpdateLastDismissed')
    const now = new Date().getTime()

    // Show if never dismissed or if 24 hours have passed
    if (!lastDismissed || (now - parseInt(lastDismissed)) > 24 * 60 * 60 * 1000) {
      this.element.showModal()
    }
  }

  dismiss() {
    // Store timestamp of dismissal
    localStorage.setItem('androidUpdateLastDismissed', new Date().getTime())
  }
}
