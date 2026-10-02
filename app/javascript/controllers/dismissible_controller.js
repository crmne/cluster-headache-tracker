import { Controller } from "@hotwired/stimulus"

// Hides a prompt on this device once dismissed. Storage can be unavailable
// (private browsing, some web views); the prompt then just hides for now.
export default class extends Controller {
  static values = { key: String }

  connect() {
    if (this.#dismissed) this.element.hidden = true
  }

  dismiss() {
    this.element.hidden = true

    try {
      localStorage.setItem(this.#storageKey, "1")
    } catch {
      // Nothing to remember it in
    }
  }

  get #dismissed() {
    try {
      return localStorage.getItem(this.#storageKey) === "1"
    } catch {
      return false
    }
  }

  get #storageKey() {
    return `dismissed:${this.keyValue}`
  }
}
