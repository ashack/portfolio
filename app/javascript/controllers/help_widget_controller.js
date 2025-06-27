import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel", "questionIcon", "closeIcon", "searchInput"]
  
  connect() {
    this.open = false
    this.handleEscape = this.handleEscape.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)
  }
  
  disconnect() {
    this.close()
  }
  
  toggle(event) {
    event?.preventDefault()
    this.open ? this.close() : this.show()
  }
  
  show(event) {
    event?.preventDefault()
    if (this.open) return
    
    this.open = true
    this.panelTarget.classList.remove("hidden")
    
    // Swap icons
    if (this.hasQuestionIconTarget) this.questionIconTarget.classList.add("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.remove("hidden")
    
    // Add event listeners
    document.addEventListener("keydown", this.handleEscape)
    document.addEventListener("click", this.handleClickOutside)
    
    // Animate in
    requestAnimationFrame(() => {
      this.panelTarget.classList.remove("scale-95", "opacity-0")
      this.panelTarget.classList.add("scale-100", "opacity-100")
      
      // Focus search input
      if (this.hasSearchInputTarget) {
        this.searchInputTarget.focus()
      }
    })
  }
  
  close() {
    if (!this.open) return
    
    this.open = false
    
    // Swap icons
    if (this.hasQuestionIconTarget) this.questionIconTarget.classList.remove("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.add("hidden")
    
    // Remove event listeners
    document.removeEventListener("keydown", this.handleEscape)
    document.removeEventListener("click", this.handleClickOutside)
    
    // Animate out
    this.panelTarget.classList.remove("scale-100", "opacity-100")
    this.panelTarget.classList.add("scale-95", "opacity-0")
    
    // Hide after animation
    setTimeout(() => {
      if (!this.open) {
        this.panelTarget.classList.add("hidden")
      }
    }, 200)
  }
  
  search(event) {
    const query = event.target.value.toLowerCase()
    
    // This is where you'd implement actual search functionality
    // For now, just log it
    console.log("Searching for:", query)
  }
  
  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
  
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}