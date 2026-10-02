import { BridgeComponent, BridgeElement } from "@hotwired/hotwire-native-bridge"

// Puts the form's submit button in the native navigation bar, disabled while submitting.
// https://github.com/joemasilotti/bridge-components/blob/main/docs/components/form.md
export default class extends BridgeComponent {
  static component = "form"
  static targets = [ "submit" ]

  connect() {
    super.connect()
    this.#addButton()
  }

  disconnect() {
    super.disconnect()
    this.#removeButton()
  }

  submitStart() {
    this.send("disableSubmit")
  }

  submitEnd() {
    this.send("enableSubmit")
  }

  #addButton() {
    const submit = new BridgeElement(this.submitTarget)
    const color = this.bridgeElement.bridgeAttribute("color")

    this.send("connect", { title: submit.title, color }, () => this.submitTarget.click())
  }

  #removeButton() {
    this.send("disconnect")
  }
}
