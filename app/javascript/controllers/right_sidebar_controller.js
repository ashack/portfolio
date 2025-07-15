import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "backdrop", "panel", "content", "minimizedIcon"]
  static values = { 
    open: { type: Boolean, default: false }
  }
  
  connect() {
    console.log('Right sidebar controller connected')
    
    // Clean up old localStorage keys from previous implementation
    localStorage.removeItem('rightSidebarExpanded')
    localStorage.removeItem('rightSidebarMinimized')
    localStorage.removeItem('rightSidebarState')
    
    // Check if drawer should be open from localStorage
    const savedOpen = localStorage.getItem('rightDrawerOpen')
    if (savedOpen !== null) {
      this.openValue = savedOpen === 'true'
    }
    
    console.log('Initial state:', { open: this.openValue, hasDrawer: this.hasDrawerTarget })
    
    // Apply initial state
    this.updateDrawerState()
  }
  
  toggle(event) {
    console.log('Toggle clicked')
    event?.preventDefault()
    this.openValue = !this.openValue
    this.saveState()
    this.updateDrawerState()
  }
  
  open(event) {
    event?.preventDefault()
    this.openValue = true
    this.saveState()
    this.updateDrawerState()
  }
  
  close(event) {
    event?.preventDefault()
    this.openValue = false
    this.saveState()
    this.updateDrawerState()
  }
  
  closeOnBackdrop(event) {
    // Only close if clicking directly on backdrop
    if (event.target === event.currentTarget) {
      this.close(event)
    }
  }
  
  updateDrawerState() {
    console.log('Updating drawer state:', { 
      hasDrawer: this.hasDrawerTarget, 
      open: this.openValue,
      drawer: this.drawerTarget
    })
    
    if (!this.hasDrawerTarget) {
      console.error('No drawer target found!')
      return
    }
    
    if (this.openValue) {
      // Show drawer
      this.drawerTarget.classList.remove('hidden')
      
      // Animate backdrop
      if (this.hasBackdropTarget) {
        this.backdropTarget.classList.remove('opacity-0')
        this.backdropTarget.classList.add('opacity-100')
      }
      
      // Animate panel
      if (this.hasPanelTarget) {
        setTimeout(() => {
          this.panelTarget.classList.remove('translate-x-full')
          this.panelTarget.classList.add('translate-x-0')
        }, 10)
      }
      
      // Prevent body scroll
      document.body.style.overflow = 'hidden'
    } else {
      // Hide drawer
      if (this.hasBackdropTarget) {
        this.backdropTarget.classList.remove('opacity-100')
        this.backdropTarget.classList.add('opacity-0')
      }
      
      if (this.hasPanelTarget) {
        this.panelTarget.classList.remove('translate-x-0')
        this.panelTarget.classList.add('translate-x-full')
      }
      
      // Hide after animation
      setTimeout(() => {
        if (!this.openValue && this.hasDrawerTarget) {
          this.drawerTarget.classList.add('hidden')
        }
      }, 300)
      
      // Re-enable body scroll
      document.body.style.overflow = ''
    }
  }
  
  saveState() {
    try {
      localStorage.setItem('rightDrawerOpen', String(this.openValue))
    } catch (e) {
      console.error('Failed to save drawer state:', e)
    }
  }
  
  // Handle escape key
  disconnect() {
    document.body.style.overflow = ''
  }
}