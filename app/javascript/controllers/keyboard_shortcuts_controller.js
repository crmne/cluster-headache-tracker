import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const DISABLED_KEY = "keyboardShortcutsDisabled"

export default class extends Controller {
  static targets = [ "dialog", "toggle" ]
  static values = { newLogUrl: String, currentAttackUrl: String }

  connect() {
    this.toggleTarget.checked = this.#enabled
  }

  handle(event) {
    if (this.#ignored(event)) return

    if (event.key === "?") {
      event.preventDefault()
      this.dialogTarget.showModal()
    } else if (this.#enabled && event.key === "n") {
      event.preventDefault()
      Turbo.visit(this.newLogUrlValue)
    } else if (this.#enabled && event.key === "e") {
      event.preventDefault()
      Turbo.visit(this.currentAttackUrlValue)
    }
  }

  toggle() {
    try {
      if (this.toggleTarget.checked) {
        localStorage.removeItem(DISABLED_KEY)
      } else {
        localStorage.setItem(DISABLED_KEY, "true")
      }
    } catch {
      // Storage can be unavailable (private mode); shortcuts then stay on for this page only.
    }
  }

  #ignored(event) {
    return event.defaultPrevented || event.repeat || event.isComposing ||
      event.ctrlKey || event.metaKey || event.altKey ||
      this.#typing(event.target) || document.querySelector("dialog[open]")
  }

  #typing(target) {
    return target instanceof Element &&
      (target.isContentEditable || target.closest("input, textarea, select") !== null)
  }

  get #enabled() {
    try {
      return localStorage.getItem(DISABLED_KEY) !== "true"
    } catch {
      return true
    }
  }
}
