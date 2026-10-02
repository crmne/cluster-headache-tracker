import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// Hands file downloads (like the PDF report) to the native shell, which
// fetches the URL with the web view's session cookies and opens it in a
// viewer or share sheet. Browsers, and shells without the "download"
// component, follow the link or submit the form as usual.
export default class extends BridgeComponent {
  static component = "download"

  download(event) {
    if (this.enabled) {
      event.preventDefault()
      this.send("download", { url: this.#url, title: this.element.dataset.downloadTitle })
    }
  }

  get #url() {
    if (this.element instanceof HTMLFormElement) {
      const url = new URL(this.element.action, window.location.href)
      url.search = new URLSearchParams(new FormData(this.element)).toString()
      return url.href
    } else {
      return new URL(this.element.href, window.location.href).href
    }
  }
}
