import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"]
  
  connect() {
    this.isOpen = false
    this.handleEscape = this.handleEscape.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)
  }
  
  disconnect() {
    this.close()
  }
  
  toggle() {
    this.isOpen ? this.close() : this.open()
  }
  
  open() {
    if (this.isOpen) return
    
    this.isOpen = true
    
    // Show menu
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove("hidden")
    }
    
    // Swap icons
    if (this.hasOpenIconTarget) this.openIconTarget.classList.add("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.remove("hidden")
    
    // Update aria-expanded on button
    const button = this.element.querySelector('[data-action*="mobile-menu#toggle"]')
    if (button) button.setAttribute("aria-expanded", "true")
    
    // Add escape listener
    document.addEventListener("keydown", this.handleEscape)
    
    // Add click outside listener with small delay to prevent immediate close
    setTimeout(() => {
      document.addEventListener("click", this.handleClickOutside)
    }, 100)
  }
  
  close() {
    if (!this.isOpen) return
    
    this.isOpen = false
    
    // Hide menu
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("hidden")
    }
    
    // Swap icons
    if (this.hasOpenIconTarget) this.openIconTarget.classList.remove("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.add("hidden")
    
    // Update aria-expanded on button
    const button = this.element.querySelector('[data-action*="mobile-menu#toggle"]')
    if (button) button.setAttribute("aria-expanded", "false")
    
    // Remove listeners
    document.removeEventListener("keydown", this.handleEscape)
    document.removeEventListener("click", this.handleClickOutside)
  }
  
  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
  
  handleClickOutside(event) {
    if (!this.element.contains(event.target) && !this.menuTarget.contains(event.target)) {
      this.close()
    }
  }
}