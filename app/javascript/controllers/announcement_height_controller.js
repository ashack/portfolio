import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Use requestAnimationFrame to ensure DOM is ready
    requestAnimationFrame(() => {
      this.updateHeight()
    })
    
    this.resizeObserver = new ResizeObserver(() => this.updateHeight())
    this.resizeObserver.observe(this.element)
    
    // Also update on window resize
    this.handleResize = this.updateHeight.bind(this)
    window.addEventListener('resize', this.handleResize)
  }

  disconnect() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
    window.removeEventListener('resize', this.handleResize)
    // Reset the CSS variable when announcement is removed
    document.documentElement.style.setProperty('--announcement-offset', '0px')
  }

  updateHeight() {
    // Ensure we get the correct height including borders
    const height = this.element.getBoundingClientRect().height
    document.documentElement.style.setProperty('--announcement-offset', `${height}px`)
    document.documentElement.style.setProperty('--announcement-height', `${height}px`)
  }

  remove() {
    // Animate the height to 0 before removing
    this.element.style.transition = 'all 0.3s ease-out'
    this.element.style.opacity = '0'
    this.element.style.marginTop = `-${this.element.offsetHeight}px`
    
    // Update CSS variable immediately for smooth transition
    document.documentElement.style.setProperty('--announcement-offset', '0px')
    document.documentElement.style.setProperty('--announcement-height', '0px')
    
    // Remove the element after animation
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}