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
      this.menuTarget.classList.add("opacity-0", "scale-95")
    }
  }
  
  disconnect() {
    this.removeEventListeners()
  }
  
  toggle(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
      event.stopImmediatePropagation()
    }
    
    this.open ? this.hide() : this.show()
    
    // Remove focus from button after mouse click to prevent focus ring
    // But keep focus for keyboard navigation (Enter/Space key)
    if (this.hasButtonTarget && event && event.type === 'click' && event.detail > 0) {
      this.buttonTarget.blur()
    }
  }
  
  show() {
    if (this.open || !this.hasMenuTarget) return
    
    this.open = true
    
    // Show with animation
    this.menuTarget.classList.remove("hidden")
    // Force reflow
    this.menuTarget.offsetHeight
    // Add transition classes
    requestAnimationFrame(() => {
      this.menuTarget.classList.remove("opacity-0", "scale-95")
      this.menuTarget.classList.add("opacity-100", "scale-100")
    })
    
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "true")
    }
    
    // Add event listeners
    document.addEventListener("keydown", this.handleEscape)
    // Delay click outside listener to prevent immediate close
    setTimeout(() => {
      document.addEventListener("click", this.handleClickOutside)
    }, 100)
    
    // Focus first menu item for accessibility
    requestAnimationFrame(() => {
      const firstLink = this.menuTarget.querySelector("a, button")
      if (firstLink) firstLink.focus()
    })
  }
  
  hide() {
    if (!this.open || !this.hasMenuTarget) return
    
    this.open = false
    
    // Hide with animation
    this.menuTarget.classList.remove("opacity-100", "scale-100")
    this.menuTarget.classList.add("opacity-0", "scale-95")
    
    // Hide after transition
    setTimeout(() => {
      if (!this.open) {
        this.menuTarget.classList.add("hidden")
      }
    }, 200)
    
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
