// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-dismiss all messages except errors after 5 seconds
    if (this.element.classList.contains("alert-error")) {
      return
    }

    this.startTimer()
  }

  startTimer() {
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, 5000)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  close(event) {
    event.preventDefault()
    this.dismiss()
  }

  dismiss() {
    this.element.classList.add("opacity-0", "translate-y-[-10px]")
    this.element.style.transition = "opacity 150ms ease, transform 150ms ease"

    setTimeout(() => {
      this.element.remove()

      // Clean up empty flash container
      const container = document.getElementById("flash-messages")
      if (container && container.childElementCount === 0) {
        container.classList.add("hidden")
      }
    }, 150)
  }
}