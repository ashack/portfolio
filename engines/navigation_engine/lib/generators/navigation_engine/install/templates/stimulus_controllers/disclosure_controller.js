import { Controller } from "@hotwired/stimulus"

// Handles expandable/collapsible navigation items
export default class extends Controller {
  static targets = ["content", "icon", "button"]

  connect() {
    // Set initial state based on aria-expanded attribute
    const isExpanded = this.buttonTarget.getAttribute("aria-expanded") === "true"
    this.updateState(isExpanded)
  }

  toggle() {
    const isExpanded = this.buttonTarget.getAttribute("aria-expanded") === "true"
    this.updateState(!isExpanded)
  }

  updateState(expand) {
    // Update aria-expanded attribute
    this.buttonTarget.setAttribute("aria-expanded", expand)

    // Show/hide content
    if (this.hasContentTarget) {
      if (expand) {
        this.contentTarget.classList.remove("hidden")
      } else {
        this.contentTarget.classList.add("hidden")
      }
    }

    // Rotate icon
    if (this.hasIconTarget) {
      if (expand) {
        this.iconTarget.classList.add("rotate-180")
      } else {
        this.iconTarget.classList.remove("rotate-180")
      }
    }
  }

  // Close when clicking outside (optional)
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.updateState(false)
    }
  }
}