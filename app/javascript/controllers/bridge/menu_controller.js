import { BridgeComponent, BridgeElement } from "@hotwired/hotwire-native-bridge"

// Adds a native navigation bar menu whose items click the matching HTML elements.
// https://github.com/joemasilotti/bridge-components/blob/main/docs/components/menu.md
export default class extends BridgeComponent {
  static component = "menu"
  static targets = [ "item" ]

  connect() {
    super.connect()
    this.#addMenuButton()
  }

  disconnect() {
    super.disconnect()
    this.#removeMenuButton()
  }

  #addMenuButton() {
    const items = this.itemTargets.map(target => {
      const item = new BridgeElement(target)

      return {
        title: item.title,
        iosImage: item.bridgeAttribute("ios-image"),
        androidImage: item.bridgeAttribute("android-image"),
        destructive: item.bridgeAttribute("destructive") == "true"
      }
    })
    const color = this.bridgeElement.bridgeAttribute("color")

    this.send("connect", { items, color }, message => {
      new BridgeElement(this.itemTargets[message.data.index]).click()
    })
  }

  #removeMenuButton() {
    this.send("disconnect")
  }
}
