import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "navigation-button"
  static targets = ["button"]

  connect() {
    super.connect()

    // Send initial button configuration
    if (this.hasButtonTarget) {
      const button = this.buttonTarget
      this.send("connect", {
        title: button.dataset.title || button.textContent.trim(),
        action: button.dataset.action || "tap",
        position: button.dataset.position || "right",
        style: button.dataset.style || "plain"
      })
    }
  }

  disconnect() {
    super.disconnect()
    this.send("disconnect")
  }

  updateButton(event) {
    const { title, action, style } = event.detail || {}
    if (title || action || style) {
      this.send("update", {
        title: title || this.buttonTarget.textContent.trim(),
        action: action || this.buttonTarget.dataset.action || "tap",
        style: style || this.buttonTarget.dataset.style || "plain"
      })
    }
  }

  // Handle button tap from native
  handleMessage(message) {
    if (message.event === "tapped" && message.data.action) {
      // Trigger the appropriate action
      switch (message.data.action) {
        case "submit":
          // Find and submit the form
          const form = this.element.closest('form') || document.querySelector('form')
          if (form) {
            form.requestSubmit()
          }
          break
        case "click":
          // Click the original button
          if (this.hasButtonTarget) {
            this.buttonTarget.click()
          }
          break
        default:
          // Dispatch a custom event
          this.element.dispatchEvent(new CustomEvent('navigation-button:tapped', {
            detail: { action: message.data.action },
            bubbles: true
          }))
      }
    }
  }
}