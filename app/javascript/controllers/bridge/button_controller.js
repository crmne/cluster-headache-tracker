import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

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
    const title = element.bridgeAttribute("title")
    const iosImage = element.bridgeAttribute("ios-image")
    const androidImage = element.bridgeAttribute("android-image")
    const data = {title, iosImage, androidImage}

    this.send("connect", data, () => {
      // Check if this is a form submit button
      const submitButton = this.element.querySelector('[type="submit"]')
      if (submitButton && submitButton.form) {
        // Submit the form
        submitButton.form.requestSubmit(submitButton)
      } else {
        // Otherwise, just click the element
        this.element.click()
      }
    })
  }

  #removeButton() {
    this.send("disconnect")
  }
}