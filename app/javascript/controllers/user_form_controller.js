import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["firstName", "lastName", "email", "systemRole", "status", "form"]
  static values = { 
    currentUserId: Number,
    targetUserId: Number,
    originalEmail: String,
    originalSystemRole: String,
    originalStatus: String
  }

  connect() {
    console.log("User form controller connected")
    this.setupValidation()
    this.storeOriginalValues()
  }

  storeOriginalValues() {
    // Store original values for change detection
    if (this.hasEmailTarget) {
      this.originalEmailValue = this.emailTarget.value
    }
    if (this.hasSystemRoleTarget) {
      this.originalSystemRoleValue = this.systemRoleTarget.value
    }
    if (this.hasStatusTarget) {
      this.originalStatusValue = this.statusTarget.value
    }
  }

  setupValidation() {
    // Add real-time validation to form fields
    if (this.hasFirstNameTarget) {
      this.firstNameTarget.addEventListener("blur", () => this.validateFirstName())
      this.firstNameTarget.addEventListener("input", () => this.clearFieldError(this.firstNameTarget))
    }

    if (this.hasLastNameTarget) {
      this.lastNameTarget.addEventListener("blur", () => this.validateLastName())
      this.lastNameTarget.addEventListener("input", () => this.clearFieldError(this.lastNameTarget))
    }

    if (this.hasEmailTarget) {
      this.emailTarget.addEventListener("blur", () => this.validateEmail())
      this.emailTarget.addEventListener("input", () => this.clearFieldError(this.emailTarget))
    }

    if (this.hasSystemRoleTarget) {
      this.systemRoleTarget.addEventListener("change", () => this.validateSystemRole())
    }
  }

  validateFirstName() {
    const firstName = this.firstNameTarget.value.trim()
    
    if (firstName.length > 50) {
      this.showFieldError(this.firstNameTarget, "First name must be 50 characters or less")
      return false
    }
    
    if (firstName && !/^[a-zA-Z\s\-'\.]*$/.test(firstName)) {
      this.showFieldError(this.firstNameTarget, "First name can only contain letters, spaces, hyphens, apostrophes, and periods")
      return false
    }
    
    this.clearFieldError(this.firstNameTarget)
    return true
  }

  validateLastName() {
    const lastName = this.lastNameTarget.value.trim()
    
    if (lastName.length > 50) {
      this.showFieldError(this.lastNameTarget, "Last name must be 50 characters or less")
      return false
    }
    
    if (lastName && !/^[a-zA-Z\s\-'\.]*$/.test(lastName)) {
      this.showFieldError(this.lastNameTarget, "Last name can only contain letters, spaces, hyphens, apostrophes, and periods")
      return false
    }
    
    this.clearFieldError(this.lastNameTarget)
    return true
  }

  validateEmail() {
    const email = this.emailTarget.value.trim().toLowerCase()
    
    if (!email) {
      this.showFieldError(this.emailTarget, "Email is required")
      return false
    }
    
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(email)) {
      this.showFieldError(this.emailTarget, "Please enter a valid email address")
      return false
    }
    
    // Check if email has actually changed
    const originalEmail = this.originalEmailValue.toLowerCase()
    if (email === originalEmail) {
      this.clearFieldError(this.emailTarget)
      return true
    }
    
    // Update the input value to normalized form
    this.emailTarget.value = email
    
    this.clearFieldError(this.emailTarget)
    return true
  }

  validateSystemRole() {
    // Prevent admins from changing their own system role
    if (this.currentUserIdValue === this.targetUserIdValue) {
      this.showFieldError(this.systemRoleTarget, "You cannot change your own system role")
      // Reset to original value
      this.systemRoleTarget.value = this.systemRoleTarget.dataset.originalValue
      return false
    }
    
    this.clearFieldError(this.systemRoleTarget)
    return true
  }

  showFieldError(field, message) {
    // Add error styling
    field.classList.add("border-red-300")
    field.classList.remove("border-gray-300")
    
    // Remove existing error message
    this.clearFieldError(field)
    
    // Add error message
    const errorDiv = document.createElement("p")
    errorDiv.className = "mt-2 text-sm text-red-600"
    errorDiv.textContent = message
    errorDiv.setAttribute("data-field-error", "true")
    
    field.parentNode.appendChild(errorDiv)
  }

  clearFieldError(field) {
    // Remove error styling
    field.classList.remove("border-red-300")
    field.classList.add("border-gray-300")
    
    // Remove error message
    const errorMessage = field.parentNode.querySelector("[data-field-error]")
    if (errorMessage) {
      errorMessage.remove()
    }
  }

  validateForm(event) {
    let isValid = true
    
    // Validate all fields
    if (this.hasFirstNameTarget && !this.validateFirstName()) isValid = false
    if (this.hasLastNameTarget && !this.validateLastName()) isValid = false
    if (this.hasEmailTarget && !this.validateEmail()) isValid = false
    if (this.hasSystemRoleTarget && !this.validateSystemRole()) isValid = false
    
    if (!isValid) {
      event.preventDefault()
      this.showFormError("Please correct the errors below before submitting.")
      return false
    }

    // Check for critical changes and show confirmation dialog
    if (this.hasCriticalChanges()) {
      event.preventDefault()
      this.showCriticalChangeConfirmation()
      return false
    }
    
    return true
  }

  hasCriticalChanges() {
    const emailChanged = this.hasEmailTarget && this.emailTarget.value !== this.originalEmailValue
    const roleChanged = this.hasSystemRoleTarget && this.systemRoleTarget.value !== this.originalSystemRoleValue
    const statusChanged = this.hasStatusTarget && this.statusTarget.value !== this.originalStatusValue
    
    return emailChanged || roleChanged || statusChanged
  }

  showCriticalChangeConfirmation() {
    const changes = this.getCriticalChanges()
    const changesList = changes.map(change => `• ${change}`).join('\n')
    
    const message = `The following critical changes will be made:\n\n${changesList}\n\nThese changes will:\n• Take effect immediately\n• Trigger email notifications to the user\n• Be logged for security auditing\n\nAre you sure you want to proceed?`
    
    // Get the confirmation modal controller
    const modalController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller~="confirmation-modal"]'),
      'confirmation-modal'
    )
    
    if (modalController) {
      modalController.show({
        title: 'Confirm Critical Changes',
        message: message,
        confirmText: 'Confirm Changes',
        cancelText: 'Cancel',
        confirmClass: 'bg-red-600 hover:bg-red-700',
        onConfirm: () => {
          // Submit the form bypassing validation
          this.submitFormDirectly()
        },
        onCancel: () => {
          // Do nothing, modal will close automatically
        }
      })
    } else {
      // Fallback to basic confirm if modal is not available
      if (confirm(message)) {
        this.submitFormDirectly()
      }
    }
  }

  submitFormDirectly() {
    // Create a hidden input to bypass validation
    const bypassInput = document.createElement('input')
    bypassInput.type = 'hidden'
    bypassInput.name = 'bypass_confirmation'
    bypassInput.value = 'true'
    this.element.appendChild(bypassInput)
    
    // Submit the form
    this.element.submit()
  }

  getCriticalChanges() {
    const changes = []
    
    if (this.hasEmailTarget && this.emailTarget.value !== this.originalEmailValue) {
      changes.push(`Email: ${this.originalEmailValue} → ${this.emailTarget.value}`)
    }
    
    if (this.hasSystemRoleTarget && this.systemRoleTarget.value !== this.originalSystemRoleValue) {
      const roleNames = {
        'user': 'User',
        'site_admin': 'Site Admin', 
        'super_admin': 'Super Admin'
      }
      changes.push(`System Role: ${roleNames[this.originalSystemRoleValue]} → ${roleNames[this.systemRoleTarget.value]}`)
    }
    
    if (this.hasStatusTarget && this.statusTarget.value !== this.originalStatusValue) {
      const statusNames = {
        'active': 'Active',
        'inactive': 'Inactive',
        'locked': 'Locked'
      }
      changes.push(`Account Status: ${statusNames[this.originalStatusValue]} → ${statusNames[this.statusTarget.value]}`)
    }
    
    return changes
  }

  showFormError(message) {
    // Create or update form-level error message
    let errorDiv = document.querySelector("[data-form-error]")
    if (!errorDiv) {
      errorDiv = document.createElement("div")
      errorDiv.className = "bg-red-50 border border-red-200 rounded-md p-4 mb-6"
      errorDiv.setAttribute("data-form-error", "true")
      errorDiv.innerHTML = `
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
            </svg>
          </div>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-red-800">${message}</h3>
          </div>
        </div>
      `
      
      // Insert at the top of the form
      const form = this.element
      form.insertBefore(errorDiv, form.firstChild)
    } else {
      errorDiv.querySelector("h3").textContent = message
    }
  }

  clearFormError() {
    const errorDiv = document.querySelector("[data-form-error]")
    if (errorDiv) {
      errorDiv.remove()
    }
  }
}