import { Controller } from "@hotwired/stimulus"
import { localDateTimeValue } from "controllers/local_time"

// Stamps a one-tap dose with the device's current time as it's submitted.
export default class extends Controller {
  static targets = [ "field" ]

  stamp() {
    this.fieldTargets.forEach(field => {
      if (field.value === "") field.value = localDateTimeValue()
    })
  }
}
