// app/javascript/controllers/share_link_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "shareButton", "shareTemplate", "copiedTemplate"]

  async share(event) {
    const button = event.currentTarget
    const url = button.dataset.shareUrl
    const title = button.dataset.shareTitle
    const text = button.dataset.shareText

    // Check if Web Share API is available (mobile/native)
    if (navigator.share) {
      try {
        await navigator.share({
          title: title,
          text: text,
          url: url
        })
      } catch (err) {
        // AbortError is thrown when user cancels the share dialog - this is expected behavior
        if (err.name !== 'AbortError') {
          console.error('Share failed:', err)
        }
      }
    } else {
      // Fallback to copy functionality
      await this.copyToClipboard()
    }
  }

  async copyToClipboard() {
    const originalHtml = this.shareButtonTarget.innerHTML

    // Create temporary textarea for iOS compatibility
    const textarea = document.createElement('textarea')
    textarea.value = this.inputTarget.value
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)

    try {
      if (navigator.userAgent.match(/ipad|iphone/i)) {
        textarea.contentEditable = true
        textarea.readOnly = false

        const range = document.createRange()
        range.selectNodeContents(textarea)
        const selection = window.getSelection()
        selection.removeAllRanges()
        selection.addRange(range)
        textarea.setSelectionRange(0, textarea.value.length)

        document.execCommand('copy')
      } else {
        textarea.select()
        document.execCommand('copy')
      }

      // Update button UI using template content
      this.shareButtonTarget.innerHTML = this.copiedTemplateTarget.innerHTML
      this.shareButtonTarget.disabled = true

      setTimeout(() => {
        this.shareButtonTarget.innerHTML = this.shareTemplateTarget.innerHTML
        this.shareButtonTarget.disabled = false
      }, 2000)
    } catch (err) {
      console.error('Copy failed', err)
    } finally {
      document.body.removeChild(textarea)
    }
  }
}
