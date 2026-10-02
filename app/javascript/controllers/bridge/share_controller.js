import { BridgeComponent } from "@hotwired/hotwire-native-bridge"
import { t } from "i18n"

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
    const title = button.dataset.shareTitle || t("share.title")
    const text = button.dataset.shareText || t("share.text")

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