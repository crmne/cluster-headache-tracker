// app/javascript/controllers/intensity_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "slider", "value", "badge", "preview" ]
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
    if (value <= 2) {
      // Green (1-2): Linear transition from bright to darker green
      const greenHue = 120
      return `hsl(${greenHue}, 80%, ${60 - (value - 1) * 10}%)`
    } else if (value <= 4) {
      // Yellow to Orange (3-4): Transition from yellow to orange
      const yellowToOrangeHue = 60 - (value - 3) * 30
      return `hsl(${yellowToOrangeHue}, 80%, 50%)`
    } else if (value <= 7) {
      // Red intensifying (5-7): Getting deeper and more saturated
      const saturation = 80 + (value - 5) * 5
      const lightness = 45 - (value - 5) * 5
      return `hsl(0, ${saturation}%, ${lightness}%)`
    } else {
      // Beyond red (8-10): Adding purple tones for extreme severity
      const purpleHue = 350 + (value - 8) * 5
      const saturation = 90 + (value - 8) * 3
      const lightness = 35 - (value - 8) * 3
      return `hsl(${purpleHue}, ${saturation}%, ${lightness}%)`
    }
  }

  updateSliderGradient() {
    const gradientStops = Array.from({ length: 10 }, (_, i) => {
      const value = i + 1
      return this.calculateColor(value)
    })

    this.sliderTarget.style.background = `linear-gradient(to right, ${gradientStops.join(', ')})`
  }

  // Called when slider value changes
  slide(event) {
    this.currentValue = parseInt(event.target.value)
    this.update()
  }
}
