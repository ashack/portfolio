import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "openIcon", "closeIcon"]
  
  connect() {
    this.open = false
    this.handleEscape = this.handleEscape.bind(this)
  }
  
  disconnect() {
    this.close()
  }
  
  toggle() {
    this.open ? this.close() : this.open()
  }
  
  open() {
    if (this.open) return
    
    this.open = true
    this.panelTarget.classList.remove("hidden")
    
    // Swap icons
    if (this.hasOpenIconTarget) this.openIconTarget.classList.add("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.remove("hidden")
    
    // Prevent body scroll
    document.body.classList.add("overflow-hidden")
    
    // Add escape listener
    document.addEventListener("keydown", this.handleEscape)
    
    // Animate in
    requestAnimationFrame(() => {
      this.panelTarget.classList.add("show")
    })
  }
  
  close() {
    if (!this.open) return
    
    this.open = false
    
    // Swap icons
    if (this.hasOpenIconTarget) this.openIconTarget.classList.remove("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.add("hidden")
    
    // Re-enable body scroll
    document.body.classList.remove("overflow-hidden")
    
    // Remove escape listener
    document.removeEventListener("keydown", this.handleEscape)
    
    // Animate out then hide
    this.panelTarget.classList.remove("show")
    setTimeout(() => {
      if (!this.open) {
        this.panelTarget.classList.add("hidden")
      }
    }, 300)
  }
  
  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}