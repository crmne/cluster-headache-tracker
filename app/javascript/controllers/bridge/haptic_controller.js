import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// Vibrates the device, on demand through the vibrate action or once when it connects.
// https://github.com/joemasilotti/bridge-components/blob/main/docs/components/haptic.md
export default class extends BridgeComponent {
  static component = "haptic"
  static values = { vibrateOnConnect: Boolean }

  connect() {
    super.connect()

    if (this.vibrateOnConnectValue && !this.vibrated) {
      this.vibrate()
    }
  }

  vibrate() {
    const feedback = this.bridgeElement.bridgeAttribute("feedback") || "success"

    this.vibrated = true
    this.send("vibrate", { feedback })
  }
}
