import { Controller } from "@hotwired/stimulus"

// Handles dismissal of site announcements
export default class extends Controller {
  dismiss() {
    // Get the announcement ID
    const announcementId = this.element.dataset.announcementId
    
    // Set a cookie to remember the dismissal (1 year expiry)
    const expiryDate = new Date()
    expiryDate.setFullYear(expiryDate.getFullYear() + 1)
    document.cookie = `announcement_${announcementId}_dismissed=true; expires=${expiryDate.toUTCString()}; path=/; SameSite=Lax`
    
    // Fade out the announcement
    this.element.style.transition = 'opacity 0.3s ease-out'
    this.element.style.opacity = '0'
    
    // Remove from DOM after animation
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}