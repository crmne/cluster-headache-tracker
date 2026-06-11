import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "startButton", "buttonText", "countdown", "dismissForm"]

  connect() {
    // Show the modal automatically when connected
    this.modalTarget.showModal()

    // Start countdown to enable button
    this.startCountdown()
  }

  startCountdown() {
    let seconds = 5 // 5 seconds to read the content

    // Show countdown
    this.buttonTextTarget.classList.add("hidden")
    this.countdownTarget.classList.remove("hidden")

    const updateCountdown = () => {
      if (seconds > 0) {
        this.countdownTarget.textContent = `${seconds}s`
        seconds--
        setTimeout(updateCountdown, 1000)
      } else {
        // Enable button and restore text
        this.startButtonTarget.disabled = false
        this.buttonTextTarget.classList.remove("hidden")
        this.countdownTarget.classList.add("hidden")
      }
    }

    updateCountdown()
  }

  acknowledge() {
    // Disable button to prevent double clicks
    this.startButtonTarget.disabled = true
    this.dismissFormTarget.requestSubmit()
  }
}
