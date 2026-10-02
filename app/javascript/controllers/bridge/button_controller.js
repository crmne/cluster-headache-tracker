import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// Adds a native navigation bar button that clicks this element, or submits the form
// of the submit button it wraps.
// https://github.com/joemasilotti/bridge-components/blob/main/docs/components/button.md
export default class extends BridgeComponent {
  static component = "button"

  connect() {
    super.connect()
    this.#addButton()
  }

  disconnect() {
    super.disconnect()
    this.#removeButton()
  }

  #addButton() {
    const element = this.bridgeElement
    const side = element.bridgeAttribute("side") || "right"
    const iosImage = element.bridgeAttribute("ios-image")
    const androidImage = element.bridgeAttribute("android-image")
    const color = element.bridgeAttribute("color")
    // A language-independent name for buttons the app handles natively (print, sign-out, sponsor),
    // since the title is translated.
    const nativeAction = element.bridgeAttribute("native-action")

    this.send(side, { title: element.title, iosImage, androidImage, color, nativeAction }, () => this.#activate())
  }

  #activate() {
    const submitter = this.element.matches("[type=submit]") ? this.element : this.element.querySelector("[type=submit]")

    if (submitter?.form) {
      submitter.form.requestSubmit(submitter)
    } else {
      this.bridgeElement.click()
    }
  }

  #removeButton() {
    this.send("disconnect")
  }
}
