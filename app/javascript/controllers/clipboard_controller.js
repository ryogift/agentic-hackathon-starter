import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "button"]

  async copy() {
    const text = this.textTarget.textContent.trim()

    try {
      await navigator.clipboard.writeText(text)
      this.showCopyFeedback()
    } catch (err) {
      this.fallbackCopy(text)
    }
  }

  fallbackCopy(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand("copy")
    document.body.removeChild(textarea)
    this.showCopyFeedback()
  }

  showCopyFeedback() {
    const originalText = this.buttonTarget.textContent
    this.buttonTarget.textContent = "コピーしました！"
    this.buttonTarget.classList.add("copied")

    setTimeout(() => {
      this.buttonTarget.textContent = originalText
      this.buttonTarget.classList.remove("copied")
    }, 2000)
  }
}
