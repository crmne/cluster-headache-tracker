import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "slider", "value", "badge" ]

  connect() {
    this.update()
  }

  update() {
    const value = parseInt(this.sliderTarget.value)
    this.valueTarget.textContent = value

    // New color calculation based on intensity
    let color
    if (value <= 2) {
      // Green (1-2): Linear transition from bright to darker green
      const greenHue = 120
      color = `hsl(${greenHue}, 80%, ${60 - (value - 1) * 10}%)`
    } else if (value <= 4) {
      // Yellow to Orange (3-4): Transition from yellow to orange
      const yellowToOrangeHue = 60 - (value - 3) * 30
      color = `hsl(${yellowToOrangeHue}, 80%, 50%)`
    } else if (value <= 7) {
      // Red intensifying (5-7): Getting deeper and more saturated
      const saturation = 80 + (value - 5) * 5
      const lightness = 45 - (value - 5) * 5
      color = `hsl(0, ${saturation}%, ${lightness}%)`
    } else {
      // Beyond red (8-10): Adding purple tones to indicate extreme severity
      const purpleHue = 350 + (value - 8) * 5
      const saturation = 90 + (value - 8) * 3
      const lightness = 35 - (value - 8) * 3
      color = `hsl(${purpleHue}, ${saturation}%, ${lightness}%)`
    }

    // Update the badge color and progress
    this.badgeTarget.style.setProperty('--value', (value / 10 * 100))
    this.badgeTarget.style.color = color

    // Update slider background gradient
    const gradientColors = [
      'hsl(120, 80%, 60%)',    // Green (1)
      'hsl(120, 80%, 50%)',    // Darker Green (2)
      'hsl(60, 80%, 50%)',     // Yellow (3)
      'hsl(30, 80%, 50%)',     // Orange (4)
      'hsl(0, 80%, 45%)',      // Red (5)
      'hsl(0, 85%, 40%)',      // Deeper Red (6)
      'hsl(0, 90%, 35%)',      // Even Deeper Red (7)
      'hsl(350, 90%, 35%)',    // Red-Purple (8)
      'hsl(355, 93%, 32%)',    // More Purple (9)
      'hsl(360, 96%, 29%)'     // Final Form (10)
    ]
    
    this.sliderTarget.style.background = `linear-gradient(to right, ${gradientColors.join(', ')})`
  }
}
