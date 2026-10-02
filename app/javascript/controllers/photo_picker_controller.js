import { Controller } from "@hotwired/stimulus"

// Previews the photos picked for upload so it's clear what will be attached.
// Formats the browser can't render (HEIC outside Safari) fall back to the file name.
export default class extends Controller {
  static targets = [ "input", "previews" ]

  preview() {
    this.previewsTarget.replaceChildren(...this.#selectedFiles.map(file => this.#previewFor(file)))
  }

  get #selectedFiles() {
    return this.inputTargets.flatMap(input => Array.from(input.files))
  }

  #previewFor(file) {
    const image = document.createElement("img")
    const url = URL.createObjectURL(file)

    image.src = url
    image.alt = file.name
    image.className = "w-20 h-20 object-cover rounded-lg bg-base-300"
    image.addEventListener("load", () => URL.revokeObjectURL(url), { once: true })
    image.addEventListener("error", () => {
      URL.revokeObjectURL(url)
      image.replaceWith(this.#nameFor(file))
    }, { once: true })

    return image
  }

  #nameFor(file) {
    const name = document.createElement("span")

    name.textContent = file.name
    name.className = "badge badge-ghost h-auto min-h-[1.5rem] whitespace-normal break-all"

    return name
  }
}
