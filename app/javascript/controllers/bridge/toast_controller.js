import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// Shows a native toast, on demand through the show action or once when it connects.
// https://github.com/joemasilotti/bridge-components/blob/main/docs/components/toast.md
export default class extends BridgeComponent {
  static component = "toast"
  static values = { showOnConnect: Boolean }

  connect() {
    super.connect()

    if (this.showOnConnectValue && !this.shown) {
      this.#showToast()
    }
  }

  show(event) {
    event.preventDefault()
    event.stopImmediatePropagation()
    this.#showToast()
  }

  #showToast() {
    const message = this.bridgeElement.bridgeAttribute("message")

    this.shown = true
    this.send("show", { message }, () => {})
  }
}
