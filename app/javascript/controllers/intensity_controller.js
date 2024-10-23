import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "slider", "value", "badge" ]

  connect() {
    this.update()
  }

  update() {
    const value = this.sliderTarget.value
    this.valueTarget.textContent = value

    // Calculate color based on intensity (green at 1, yellow at 5, red at 10)
    const hue = 120 - (value - 1) * 12 // 120 is green, 0 is red
    const color = `hsl(${hue}, 80%, 40%)`

    // Update the badge color and progress
    this.badgeTarget.style.setProperty('--value', (value / 10 * 100))
    this.badgeTarget.style.color = color
  }
}
