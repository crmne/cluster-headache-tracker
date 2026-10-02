import { BridgeComponent } from "@hotwired/hotwire-native-bridge"
import { Turbo } from "@hotwired/turbo-rails"

const webConfirm = Turbo.config.forms.confirm

// Answers every data-turbo-confirm with a native alert instead of window.confirm.
// The submitter or its form can refine the alert with data-bridge-title, -description,
// -confirm, -dismiss and -destructive. DELETE forms are destructive by default.
// https://github.com/joemasilotti/bridge-components/blob/main/docs/components/alert.md
export default class extends BridgeComponent {
  static component = "alert"
  static values = { confirm: String, destructiveConfirm: String, dismiss: String }

  connect() {
    super.connect()
    Turbo.config.forms.confirm = this.confirm
  }

  disconnect() {
    super.disconnect()
    this.#answer(false)

    if (Turbo.config.forms.confirm === this.confirm) {
      Turbo.config.forms.confirm = webConfirm
    }
  }

  confirm = (message, form, submitter) => {
    this.#answer(false)

    if (this.enabled) {
      return new Promise(resolve => {
        this.pendingAnswer = resolve
        this.send("show", this.#alertFor(message, form, submitter), () => this.#answer(true))
      })
    } else {
      return Promise.resolve(window.confirm(message))
    }
  }

  #alertFor(message, form, submitter) {
    const attribute = name => submitter?.getAttribute(`data-bridge-${name}`) ?? form.getAttribute(`data-bridge-${name}`)
    const destructive = attribute("destructive") ? attribute("destructive") == "true" : this.#deleting(form)

    return {
      title: attribute("title") || message,
      description: attribute("description"),
      destructive,
      confirm: attribute("confirm") || (destructive ? this.destructiveConfirmValue : this.confirmValue),
      dismiss: attribute("dismiss") || this.dismissValue
    }
  }

  #deleting(form) {
    return form.querySelector("input[name=_method]")?.value?.toLowerCase() == "delete"
  }

  #answer(confirmed) {
    this.pendingAnswer?.(confirmed)
    this.pendingAnswer = null
  }
}
