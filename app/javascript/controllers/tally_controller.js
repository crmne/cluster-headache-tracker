// app/javascript/controllers/tally_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Check if Tally is already loaded
    if (window.Tally) {
      this.loadTally()
    } else {
      // If not loaded, wait for it
      document.addEventListener('tally-loaded', this.loadTally.bind(this), { once: true })
    }
  }

  loadTally() {
    // Force Tally to scan for and load forms
    window.Tally.loadEmbeds()
  }
}
