import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// Hands the app the attack status it shows in home screen widgets and quick actions:
// { ongoing, startedAt, lastAttackAt, attackFreeDays, attacksToday, locale }
export default class extends BridgeComponent {
  static component = "widget-status"
  static values = { payload: Object }

  connect() {
    super.connect()
    this.#sendStatus()
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
