import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// Hands the app the attack status it shows in home screen widgets and quick actions:
// { ongoing, startedAt, lastAttackAt, attackFreeDays, attacksToday, locale }
//
// Signed out (after signing out elsewhere, an expired session or a deleted account) it
// sends `clear` instead, so nothing from the last account stays on the home screen.
// Apps that predate `clear` ignore it.
export default class extends BridgeComponent {
  static component = "widget-status"
  static values = { payload: Object, signedOut: Boolean }

  connect() {
    super.connect()

    if (this.signedOutValue) {
      this.send("clear", {})
    } else {
      this.#sendStatus()
    }
  }

  payloadValueChanged() {
    if (this.sentStatus !== undefined) this.#sendStatus()
  }

  #sendStatus() {
    const status = JSON.stringify(this.payloadValue)

    if (status != this.sentStatus) {
      this.sentStatus = status
      this.send("connect", this.payloadValue)
    }
  }
}
