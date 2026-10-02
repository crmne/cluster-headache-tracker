import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// Tells the app which appearance the web content uses so the native chrome (status bar,
// navigation and tab bars) matches it. An empty theme means "follow the system", which
// is what the web UI does through prefers-color-scheme.
// https://github.com/joemasilotti/bridge-components/blob/main/docs/components/theme.md
export default class extends BridgeComponent {
  static component = "theme"
  static values = { theme: String }

  connect() {
    super.connect()
    this.#setTheme()
  }

  themeValueChanged() {
    if (this.sentTheme !== undefined) this.#setTheme()
  }

  #setTheme() {
    this.sentTheme = this.themeValue || null
    this.send("connect", { theme: this.sentTheme })
  }
}
