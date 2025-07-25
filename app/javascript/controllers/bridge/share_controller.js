import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "share"
  static targets = ["shareButton"]

  shareViaBridge(event) {
    // Only handle if bridge is available
    if (!this.isBridgeAvailable) return

    // Prevent default behavior and stop propagation
    event.preventDefault()
    event.stopImmediatePropagation()

    const button = this.shareButtonTarget
    const url = button.dataset.shareUrl
    const title = button.dataset.shareTitle || "My Headache Logs"
    const text = button.dataset.shareText || "View my headache tracking history"

    console.log("Sending share to native:", { url, title, text })

    // Send share event to native
    this.send("share", { url, title, text }, () => {
      console.log("Share sheet presented")
    })
  }

  get isBridgeAvailable() {
    return this.bridge !== undefined
  }
}