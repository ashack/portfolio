import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "title", "message", "confirmButton", "cancelButton"]
  static values = { 
    title: String,
    message: String,
    confirmText: String,
    cancelText: String,
    confirmClass: String
  }

  connect() {
    this.onConfirm = null
    this.onCancel = null
  }

  show(options = {}) {
    // Set content
    this.titleTarget.textContent = options.title || this.titleValue || "Confirm Action"
    this.messageTarget.innerHTML = options.message || this.messageValue || "Are you sure?"
    
    // Set button text
    this.confirmButtonTarget.textContent = options.confirmText || this.confirmTextValue || "Confirm"
    this.cancelButtonTarget.textContent = options.cancelText || this.cancelTextValue || "Cancel"
    
    // Set button styling
    const confirmClass = options.confirmClass || this.confirmClassValue || "bg-red-600 hover:bg-red-700"
    this.confirmButtonTarget.className = `w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 text-base font-medium text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm ${confirmClass}`
    
    // Store callbacks
    this.onConfirm = options.onConfirm
    this.onCancel = options.onCancel
    
    // Show modal
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    
    // Focus cancel button by default
    this.cancelButtonTarget.focus()
  }

  hide() {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  confirm(event) {
    event.preventDefault()
    
    if (this.onConfirm) {
      this.onConfirm()
    }
    
    this.hide()
  }

  cancel(event) {
    event.preventDefault()
    
    if (this.onCancel) {
      this.onCancel()
    }
    
    this.hide()
  }

  // Close on backdrop click
  backdropClick(event) {
    if (event.target === this.modalTarget) {
      this.cancel(event)
    }
  }

  // Handle escape key
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.cancel(event)
    }
  }
}