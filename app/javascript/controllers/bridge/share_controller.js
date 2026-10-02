import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// Presents the native share sheet instead of the Web Share API or clipboard fallback.
// https://github.com/joemasilotti/bridge-components/blob/main/docs/components/share.md
export default class extends BridgeComponent {
  static component = "share"
  static targets = [ "shareButton" ]

  shareViaBridge(event) {
    if (this.enabled) {
      event.preventDefault()
      event.stopImmediatePropagation()

      const { shareUrl: url, shareTitle: title, shareText: text } = this.shareButtonTarget.dataset
      this.send("share", { url, title, text })
    }
  }
}
