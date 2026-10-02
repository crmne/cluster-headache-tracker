import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// Asks the app for the App Store / Google Play review prompt after a short pause, then
// records the request so it isn't repeated.
// https://github.com/joemasilotti/bridge-components/blob/main/docs/components/review-prompt.md
export default class extends BridgeComponent {
  static component = "review-prompt"
  static values = { url: String, delay: { type: Number, default: 3000 } }

  connect() {
    super.connect()

    if (!this.prompted) {
      clearTimeout(this.timeout)
      this.timeout = setTimeout(() => this.#promptForReview(), this.delayValue)
    }
  }

  disconnect() {
    super.disconnect()
    clearTimeout(this.timeout)
  }

  #promptForReview() {
    if (document.visibilityState == "visible" && !this.prompted) {
      this.prompted = true
      this.send("prompt")
      this.#recordPrompt()
    }
  }

  #recordPrompt() {
    const token = document.querySelector("meta[name=csrf-token]")?.content
    fetch(this.urlValue, { method: "POST", headers: { "X-CSRF-Token": token } })
  }
}
