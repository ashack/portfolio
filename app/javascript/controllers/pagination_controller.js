import { Controller } from "@hotwired/stimulus"

// Handles pagination interactions including:
// - Items per page selection
// - Page jumping
// - Form submission
// - Loading states
export default class extends Controller {
  static values = { 
    turboFrame: String,
    loadingClass: { type: String, default: "opacity-50" }
  }

  connect() {
    // Add loading indicator support
    this.element.setAttribute("data-pagination-loading", "false")
  }

  // Submit form when items per page is changed
  submitForm(event) {
    const form = event.target.closest("form")
    if (form) {
      this.showLoading()
      form.requestSubmit()
    }
  }

  // Handle page jump form submission
  jumpToPage(event) {
    event.preventDefault()
    const form = event.target.closest("form")
    const pageInput = form.querySelector("input[name='page']")
    
    if (pageInput) {
      const page = parseInt(pageInput.value)
      const max = parseInt(pageInput.max)
      const min = parseInt(pageInput.min)
      
      // Validate page number
      if (page >= min && page <= max) {
        this.showLoading()
        form.requestSubmit()
      } else {
        // Reset to current page if invalid
        pageInput.value = pageInput.defaultValue
        this.showError(`Please enter a page number between ${min} and ${max}`)
      }
    }
  }

  // Show loading state
  showLoading() {
    this.element.setAttribute("data-pagination-loading", "true")
    
    // Add loading class to results if turbo frame specified
    if (this.hasTurboFrameValue) {
      const frame = document.querySelector(`turbo-frame#${this.turboFrameValue}`)
      if (frame) {
        frame.classList.add(this.loadingClassValue)
      }
    }
  }

  // Hide loading state (called by Turbo after load)
  hideLoading() {
    this.element.setAttribute("data-pagination-loading", "false")
    
    if (this.hasTurboFrameValue) {
      const frame = document.querySelector(`turbo-frame#${this.turboFrameValue}`)
      if (frame) {
        frame.classList.remove(this.loadingClassValue)
      }
    }
  }

  // Show error message
  showError(message) {
    // Create or update error element
    let errorEl = this.element.querySelector("[data-pagination-error]")
    
    if (!errorEl) {
      errorEl = document.createElement("div")
      errorEl.setAttribute("data-pagination-error", "")
      errorEl.className = "text-sm text-red-600 mt-1"
      this.element.querySelector(".page-jump").appendChild(errorEl)
    }
    
    errorEl.textContent = message
    
    // Remove error after 3 seconds
    setTimeout(() => {
      errorEl.remove()
    }, 3000)
  }

  // Handle keyboard shortcuts
  keydown(event) {
    // Cmd/Ctrl + Arrow keys for navigation
    if ((event.metaKey || event.ctrlKey) && event.key === "ArrowLeft") {
      event.preventDefault()
      this.navigateToPrevious()
    } else if ((event.metaKey || event.ctrlKey) && event.key === "ArrowRight") {
      event.preventDefault()
      this.navigateToNext()
    }
  }

  navigateToPrevious() {
    const prevLink = this.element.querySelector("a[rel='prev']")
    if (prevLink) {
      this.showLoading()
      prevLink.click()
    }
  }

  navigateToNext() {
    const nextLink = this.element.querySelector("a[rel='next']")
    if (nextLink) {
      this.showLoading()
      nextLink.click()
    }
  }

  // Listen for Turbo events to manage loading states
  disconnect() {
    // Clean up any loading states
    this.hideLoading()
  }
}