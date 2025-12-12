import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  toggle() {
    const isHidden = this.contentTarget.hidden
    this.contentTarget.hidden = !isHidden
    this.iconTarget.textContent = isHidden ? "-" : "+"
  }
}
