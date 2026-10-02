import { Controller } from "@hotwired/stimulus"
import { localDateTimeValue } from "controllers/local_time"

// One tap on a medication adds a dose taken now to the headache log form.
// Doses for attacks logged after the fact default to the attack's start.
const BACKDATED_AFTER_MINUTES = 6 * 60

export default class extends Controller {
  static targets = [ "doses", "newForm", "newToggle", "newName", "newKind", "newTemplate", "dose" ]
  static values = { startTimeField: String }

  add({ params: { template } }) {
    const row = this.#rowFrom(document.getElementById(template))
    this.#append(row)
  }

  toggleNew() {
    const hidden = !this.newFormTarget.hidden
    this.newFormTarget.hidden = hidden
    this.newToggleTarget.setAttribute("aria-expanded", String(!hidden))

    if (!hidden) this.newNameTarget.focus()
  }

  addNew() {
    const name = this.newNameTarget.value.trim()
    if (name === "") {
      this.newNameTarget.focus()
      return
    }

    const kind = this.newKindTargets.find(input => input.checked)?.value || "abortive"
    const row = this.#rowFrom(this.newTemplateTarget)
    this.#field(row, "name").value = name
    this.#field(row, "kind").value = kind
    this.#field(row, "label").textContent = name
    this.#append(row)

    this.newNameTarget.value = ""
    this.toggleNew()
  }

  remove(event) {
    const row = event.target.closest("[data-medication-picker-target='dose']")
    const destroyField = this.#field(row, "destroy")

    if (row.dataset.persisted === "true") {
      destroyField.value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
  }

  #rowFrom(template) {
    const html = template.innerHTML.replace(/NEW_DOSE/g, `${Date.now()}${Math.floor(Math.random() * 1000)}`)
    const container = document.createElement("div")
    container.innerHTML = html.trim()
    return container.firstElementChild
  }

  #append(row) {
    this.#field(row, "taken_at").value = this.#takenAt()
    this.dosesTarget.append(row)
  }

  #takenAt() {
    const startTime = document.getElementById(this.startTimeFieldValue)?.value
    const now = localDateTimeValue()

    if (startTime && (new Date(now) - new Date(startTime)) / 60000 > BACKDATED_AFTER_MINUTES) {
      return startTime
    } else {
      return now
    }
  }

  #field(row, name) {
    return row.querySelector(`[data-medication-picker-field='${name}']`)
  }
}
