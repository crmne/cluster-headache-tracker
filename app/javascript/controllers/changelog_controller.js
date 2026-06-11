import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['dismissForm']

  connect() {
    this.handleCancel = this.dismiss.bind(this)
    this.element.addEventListener('cancel', this.handleCancel)

    // Show the modal when the controller connects
    // Don't auto-show if welcome modal is present
    const welcomeModal = document.getElementById('welcomeModal')
    if (!welcomeModal || welcomeModal.getAttribute('data-controller') === null) {
      this.element.showModal()
    }
  }

  disconnect() {
    this.element.removeEventListener('cancel', this.handleCancel)
  }

  dismiss(event) {
    event.preventDefault()
    this.dismissFormTarget.requestSubmit()
  }
}
