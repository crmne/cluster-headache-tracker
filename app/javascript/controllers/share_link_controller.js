// app/javascript/controllers/share_link_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "shareButton", "shareTemplate", "copiedTemplate"]

  async share(event) {
    const button = event.currentTarget
    const url = button.dataset.shareUrl
    const title = button.dataset.shareTitle
    const text = button.dataset.shareText

    // Check if Web Share API is available and likely to work
    // Note: navigator.share exists on some desktop browsers but doesn't work properly
    const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)
    if (navigator.share && isMobile) {
      try {
        await navigator.share({
          title: title,
          text: text,
          url: url
        })
      } catch (err) {
        // If share fails for any reason, fallback to copy
        await this.copyToClipboard()
      }
    } else {
      // Fallback to copy functionality for desktop or unsupported browsers
      await this.copyToClipboard()
    }
  }

  async copyToClipboard() {
    try {
      await navigator.clipboard.writeText(this.inputTarget.value)

      // Update button UI using template content
      this.shareButtonTarget.innerHTML = this.copiedTemplateTarget.innerHTML
      this.shareButtonTarget.disabled = true

      setTimeout(() => {
        this.shareButtonTarget.innerHTML = this.shareTemplateTarget.innerHTML
        this.shareButtonTarget.disabled = false
      }, 2000)
    } catch (err) {
      console.error('Copy failed', err)
    }
  }
}
