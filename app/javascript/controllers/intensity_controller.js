// app/javascript/controllers/intensity_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "slider", "value", "badge", "preview", "glow" ]
  static values = {
    current: Number,
    min: { type: Number, default: 1 },
    max: { type: Number, default: 10 }
  }

  connect() {
    // Set initial value from form or default
    this.currentValue = parseInt(this.sliderTarget.value) || this.minValue
    this.update()
  }

  update() {
    const value = this.currentValue
    this.valueTarget.textContent = value

    // Update preview text based on intensity
    if (this.hasPreviewTarget) {
      this.previewTarget.textContent = this.getIntensityDescription(value)
    }

    // Calculate color based on severity scale
    const color = this.calculateColor(value)

    // Update visual elements
    this.badgeTarget.style.setProperty('--value', (value / this.maxValue * 100))
    this.badgeTarget.style.color = color

    // Update glow effect if present
    if (this.hasGlowTarget) {
      this.glowTarget.style.backgroundColor = color
    }

    // Update slider appearance
    this.updateSliderGradient()
  }

  // Map intensity values to meaningful descriptions
  getIntensityDescription(value) {
    const descriptions = {
      1: "Mild eye pressure, barely noticeable.",
      2: "Light throbbing on one side, slight eye discomfort.",
      3: "Persistent pressure with occasional sharp pains.",
      4: "Sharp eye pain with throbbing, mild tearing.",
      5: "Strong burning sensation, tender temple area, affects focus.",
      6: "Severe piercing waves, eye tearing, nasal congestion.",
      7: "Intense burning/stabbing, drooping eyelid, disrupts activities.",
      8: "Like a hot poker through eye, forces pacing for relief.",
      9: "Excruciating pressure/stabbing, feels like eye might explode.",
      10: "Unbearable torture-like pain, completely incapacitating."
    }
    return descriptions[value] || ""
  }

  calculateColor(value) {
    // Smooth interpolation between green, yellow, and red
    if (value <= 3) {
      // Green range (1-3)
      return 'hsl(142, 71%, 45%)'
    } else if (value <= 6) {
      // Interpolate from green to yellow (3-6)
      const ratio = (value - 3) / 3
      const hue = 142 - (ratio * (142 - 45)) // 142 (green) to 45 (yellow)
      const saturation = 71 + (ratio * (93 - 71)) // 71% to 93%
      const lightness = 45 + (ratio * (47 - 45)) // 45% to 47%
      return `hsl(${Math.round(hue)}, ${Math.round(saturation)}%, ${Math.round(lightness)}%)`
    } else {
      // Interpolate from yellow to red (6-10)
      const ratio = (value - 6) / 4
      const hue = 45 * (1 - ratio) // 45 (yellow) to 0 (red)
      const saturation = 93 - (ratio * (93 - 84)) // 93% to 84%
      const lightness = 47 + (ratio * (60 - 47)) // 47% to 60%
      return `hsl(${Math.round(hue)}, ${Math.round(saturation)}%, ${Math.round(lightness)}%)`
    }
  }

  updateSliderGradient() {
    // Create a smooth gradient by calculating colors at each point
    const stops = []
    for (let i = 1; i <= 10; i++) {
      const color = this.calculateColor(i)
      const position = ((i - 1) / 9) * 100
      stops.push(`${color} ${position}%`)
    }

    this.sliderTarget.style.background = `linear-gradient(to right, ${stops.join(', ')})`
  }

  // Called when slider value changes
  slide(event) {
    this.currentValue = parseInt(event.target.value)
    this.update()
  }
}
