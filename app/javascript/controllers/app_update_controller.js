import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    latestVersion: String,
    platform: String,
    required: Boolean
  }

  connect() {
    if (this.requiredValue) {
      this.element.showModal()
    } else if (!this.otherModalOpen() && this.dismissalExpired()) {
      this.element.showModal()
    }
  }

  dismiss() {
    if (!this.requiredValue) {
      localStorage.setItem(this.dismissalKey(), Date.now().toString())
    }
  }

  dismissalExpired() {
    const lastDismissed = localStorage.getItem(this.dismissalKey())
    const now = Date.now()

    if (lastDismissed) {
      return (now - parseInt(lastDismissed, 10)) > 7 * 24 * 60 * 60 * 1000
    } else {
      return true
    }
  }

  dismissalKey() {
    return `appUpdate:${this.platformValue}:${this.latestVersionValue}`
  }

  otherModalOpen() {
    return document.getElementById("welcomeModal") || document.getElementById("changelogModal")
  }
}
