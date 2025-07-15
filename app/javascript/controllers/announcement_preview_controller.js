import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "message", "style", "dismissible", "content", "previewTitle", "previewMessage", "dismissButton"]

  connect() {
    this.updatePreview()
  }

  updatePreview() {
    // Update title
    const title = this.titleTarget.value || 'Your announcement title will appear here'
    this.previewTitleTarget.textContent = title

    // Update message
    const message = this.messageTarget.value || 'Your announcement message will appear here'
    this.previewMessageTarget.textContent = message

    // Update style
    this.updateStyle()

    // Update dismissible button visibility
    if (this.hasDismissButtonTarget) {
      this.dismissButtonTarget.style.display = this.dismissibleTarget.checked ? 'block' : 'none'
    }
  }

  updateStyle() {
    const style = this.styleTarget.value
    const baseClasses = 'px-4 py-3 rounded-lg border relative flex items-start'
    
    // Style classes mapping matching the actual announcement display
    const styleClasses = {
      'info': 'bg-blue-50 border-blue-200 text-blue-800',
      'success': 'bg-green-50 border-green-200 text-green-800',
      'warning': 'bg-yellow-50 border-yellow-200 text-yellow-800',
      'danger': 'bg-red-50 border-red-200 text-red-800'
    }

    this.contentTarget.className = `${baseClasses} ${styleClasses[style] || styleClasses['info']}`
    
    // Update icon
    this.updateIcon(style)
  }

  updateIcon(style) {
    const iconMap = {
      'info': 'info',
      'success': 'check-circle',
      'warning': 'warning-circle',
      'danger': 'x-circle'
    }

    const iconColor = {
      'info': 'text-blue-400',
      'success': 'text-green-400',
      'warning': 'text-yellow-400',
      'danger': 'text-red-400'
    }[style] || 'text-blue-400'

    // Update icon color by changing the class
    const iconContainer = this.contentTarget.querySelector('[data-announcement-icon]')
    if (iconContainer) {
      const svg = iconContainer.querySelector('svg')
      if (svg) {
        // Remove old color classes
        svg.classList.remove('text-blue-400', 'text-green-400', 'text-yellow-400', 'text-red-400')
        // Add new color class
        svg.classList.add(iconColor)
      }
    }
  }
}