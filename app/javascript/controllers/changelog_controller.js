import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { version: String }

  connect() {
    // Show the modal when the controller connects
    // Don't auto-show if welcome modal is present
    const welcomeModal = document.getElementById('welcomeModal')
    if (!welcomeModal || welcomeModal.getAttribute('data-controller') === null) {
      this.element.showModal()
    }
  }

  acknowledge() {
    // Update the user's last_seen_changelog via an AJAX request
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch('/settings/changelog_acknowledged', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        version: this.versionValue
      })
    })
    .then(response => {
      if (!response.ok) {
        console.error('Failed to acknowledge changelog')
      }
    })
    .catch(error => {
      console.error('Error acknowledging changelog:', error)
    })
  }

  async share(event) {
    // Prevent default and let bridge handle if available
    event.preventDefault()

    const button = event.currentTarget
    const url = button.dataset.shareUrl
    const title = button.dataset.shareTitle
    const text = button.dataset.shareText

    // Fallback for web share API if bridge doesn't handle it
    if (navigator.share && !window.webkit && !window.HotwireNative) {
      try {
        await navigator.share({
          title: title,
          text: text,
          url: url
        })
      } catch (err) {
        // User cancelled or share failed
        console.log('Share cancelled or failed:', err)
      }
    } else if (!window.webkit && !window.HotwireNative) {
      // Fallback to copying to clipboard
      try {
        await navigator.clipboard.writeText(url)
        // Visual feedback that link was copied
        const originalHTML = button.innerHTML
        button.innerHTML = `
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
          <span>Copied!</span>
        `
        button.classList.add('btn-success')
        button.classList.remove('btn-primary')

        setTimeout(() => {
          button.innerHTML = originalHTML
          button.classList.remove('btn-success')
          button.classList.add('btn-primary')
        }, 2000)
      } catch (err) {
        console.error('Failed to copy:', err)
      }
    }
  }
}