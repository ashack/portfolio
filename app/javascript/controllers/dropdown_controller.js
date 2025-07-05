import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]
  
  connect() {
    this.open = false
    this.handleEscape = this.handleEscape.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)
    
    // Ensure menu is hidden on connect
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("hidden")
    }
  }
  
  disconnect() {
    this.removeEventListeners()
  }
  
  toggle(event) {
    event.stopPropagation()
    this.open ? this.hide() : this.show()
    
    // Remove focus from button after mouse click to prevent focus ring
    // But keep focus for keyboard navigation (Enter/Space key)
    if (this.hasButtonTarget && event.type === 'click' && event.detail > 0) {
      this.buttonTarget.blur()
    }
  }
  
  show() {
    if (this.open || !this.hasMenuTarget) return
    
    this.open = true
    this.menuTarget.classList.remove("hidden")
    
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "true")
    }
    
    // Add event listeners
    document.addEventListener("keydown", this.handleEscape)
    document.addEventListener("click", this.handleClickOutside)
    
    // Focus first menu item for accessibility
    requestAnimationFrame(() => {
      const firstLink = this.menuTarget.querySelector("a, button")
      if (firstLink) firstLink.focus()
    })
  }
  
  hide() {
    if (!this.open || !this.hasMenuTarget) return
    
    this.open = false
    this.menuTarget.classList.add("hidden")
    
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }
    
    this.removeEventListeners()
  }
  
  handleEscape(event) {
    if (event.key === "Escape") {
      this.hide()
    }
  }
  
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
  
  removeEventListeners() {
    document.removeEventListener("keydown", this.handleEscape)
    document.removeEventListener("click", this.handleClickOutside)
  }
}
