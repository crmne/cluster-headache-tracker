// app/javascript/controllers/share_link_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button", "copyTemplate", "copiedTemplate"]

  connect() {
    // Handle accordion behavior
    document.addEventListener('click', this.handleAccordion.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.handleAccordion.bind(this))
  }

  handleAccordion(event) {
    const summary = event.target.closest('summary')
    if (summary) {
      const details = summary.parentElement
      const otherDetails = document.querySelector(`details[data-accordion]:not([data-accordion="${details.dataset.accordion}"])`)
      if (otherDetails && otherDetails.open) {
        otherDetails.open = false
      }
    }
  }

  async copy() {
    const originalHtml = this.buttonTarget.innerHTML

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
      this.buttonTarget.innerHTML = this.copiedTemplateTarget.innerHTML
      this.buttonTarget.disabled = true

      setTimeout(() => {
        this.buttonTarget.innerHTML = this.copyTemplateTarget.innerHTML
        this.buttonTarget.disabled = false
      }, 2000)
    } catch (err) {
      console.error('Copy failed', err)
    } finally {
      document.body.removeChild(textarea)
    }
  }
}
