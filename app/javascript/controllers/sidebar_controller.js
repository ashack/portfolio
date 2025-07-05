import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu", "mobilePanel", "backdrop"]
  static classes = ["open", "closed"]
  
  connect() {
    this.isOpen = false
    this.mobileMenuTarget.classList.add("hidden")
  }
  
  toggle() {
    this.isOpen = !this.isOpen
    
    if (this.isOpen) {
      this.open()
    } else {
      this.close()
    }
  }
  
  open() {
    this.isOpen = true
    
    // Show the mobile menu
    this.mobileMenuTarget.classList.remove("hidden")
    this.mobileMenuTarget.classList.add("fixed")
    
    // Trigger animations after a frame to ensure transitions work
    requestAnimationFrame(() => {
      // Animate backdrop
      if (this.hasBackdropTarget) {
        this.backdropTarget.classList.remove("opacity-0")
        this.backdropTarget.classList.add("opacity-100")
      }
      
      // Animate panel
      if (this.hasMobilePanelTarget) {
        this.mobilePanelTarget.classList.remove("-translate-x-full")
        this.mobilePanelTarget.classList.add("translate-x-0")
      }
    })
    
    // Prevent body scroll when menu is open
    document.body.style.overflow = 'hidden'
  }
  
  close() {
    this.isOpen = false
    
    // Animate out
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("opacity-100")
      this.backdropTarget.classList.add("opacity-0")
    }
    
    if (this.hasMobilePanelTarget) {
      this.mobilePanelTarget.classList.remove("translate-x-0")
      this.mobilePanelTarget.classList.add("-translate-x-full")
    }
    
    // Hide after animation completes
    setTimeout(() => {
      if (!this.isOpen) {
        this.mobileMenuTarget.classList.add("hidden")
        this.mobileMenuTarget.classList.remove("fixed")
      }
    }, 300)
    
    // Re-enable body scroll
    document.body.style.overflow = ''
  }
  
  // Close when clicking escape key
  disconnect() {
    document.body.style.overflow = ''
  }
}