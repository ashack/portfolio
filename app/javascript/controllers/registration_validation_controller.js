import { Controller } from "@hotwired/stimulus"

// Stimulus controller for client-side registration form validation
// Provides real-time feedback and prevents submission of invalid data
// Matches server-side validation rules for consistency
export default class extends Controller {
  // Define targets that map to form elements via data-registration-validation-target attributes
  static targets = ["firstName", "lastName", "email", "password", "passwordConfirmation", "termsCheckbox", "privacyCheckbox", "submitButton", "error"]

  // Called when controller connects to the DOM
  connect() {
    this.validateForm()
  }

  // Sets up event listeners for all form fields
  validateForm() {
    // First name validation
    // - Validates on blur (when user leaves field)
    // - Clears error on input (while typing)
    if (this.hasFirstNameTarget) {
      this.firstNameTarget.addEventListener('blur', () => this.validateFirstName())
      this.firstNameTarget.addEventListener('input', () => this.clearError(this.firstNameTarget))
    }
    
    if (this.hasLastNameTarget) {
      this.lastNameTarget.addEventListener('blur', () => this.validateLastName())
      this.lastNameTarget.addEventListener('input', () => this.clearError(this.lastNameTarget))
    }
    
    if (this.hasEmailTarget) {
      this.emailTarget.addEventListener('blur', () => this.validateEmail())
      this.emailTarget.addEventListener('input', () => this.clearError(this.emailTarget))
    }
    
    if (this.hasPasswordTarget) {
      this.passwordTarget.addEventListener('blur', () => this.validatePassword())
      this.passwordTarget.addEventListener('input', () => {
        this.clearError(this.passwordTarget)
        this.showPasswordRequirements()
      })
    }
    
    if (this.hasPasswordConfirmationTarget) {
      this.passwordConfirmationTarget.addEventListener('blur', () => this.validatePasswordConfirmation())
      this.passwordConfirmationTarget.addEventListener('input', () => this.clearError(this.passwordConfirmationTarget))
    }

    // Legal agreement checkboxes validation
    // - Validates on change (when checkbox is clicked)
    // - Updates submit button state based on checkbox status
    if (this.hasTermsCheckboxTarget) {
      this.termsCheckboxTarget.addEventListener('change', () => this.validateCheckboxes())
    }
    
    if (this.hasPrivacyCheckboxTarget) {
      this.privacyCheckboxTarget.addEventListener('change', () => this.validateCheckboxes())
    }
  }

  // Validates first name field
  // Rules match server-side validation in User model
  validateFirstName() {
    const value = this.firstNameTarget.value.trim()
    // Regex allows letters, spaces, hyphens, apostrophes, and periods
    // This matches the server-side validation pattern
    const nameRegex = /^[a-zA-Z\s\-'\.]*$/
    
    // Check if field is empty
    if (value === '') {
      this.showError(this.firstNameTarget, "First name is required")
      return false
    }
    
    // Check if contains invalid characters
    if (!nameRegex.test(value)) {
      this.showError(this.firstNameTarget, "First name can only contain letters, spaces, hyphens, apostrophes, and periods")
      return false
    }
    
    // Check length constraint (matches User model validation)
    if (value.length > 50) {
      this.showError(this.firstNameTarget, "First name must be 50 characters or less")
      return false
    }
    
    // Validation passed - clear any existing errors
    this.clearError(this.firstNameTarget)
    return true
  }

  validateLastName() {
    const value = this.lastNameTarget.value.trim()
    const nameRegex = /^[a-zA-Z\s\-'\.]*$/
    
    if (value === '') {
      this.showError(this.lastNameTarget, "Last name is required")
      return false
    }
    
    if (!nameRegex.test(value)) {
      this.showError(this.lastNameTarget, "Last name can only contain letters, spaces, hyphens, apostrophes, and periods")
      return false
    }
    
    if (value.length > 50) {
      this.showError(this.lastNameTarget, "Last name must be 50 characters or less")
      return false
    }
    
    this.clearError(this.lastNameTarget)
    return true
  }

  // Validates email field
  // Uses basic email regex that matches most common email formats
  validateEmail() {
    const value = this.emailTarget.value.trim()
    // Basic email validation regex
    // Checks for: something@something.something
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    
    // Check if field is empty
    if (value === '') {
      this.showError(this.emailTarget, "Email is required")
      return false
    }
    
    // Check email format
    if (!emailRegex.test(value)) {
      this.showError(this.emailTarget, "Please enter a valid email address")
      return false
    }
    
    // Validation passed
    this.clearError(this.emailTarget)
    return true
  }

  // Validates password field with strong password requirements
  // Must match server-side password_complexity validation
  validatePassword() {
    const value = this.passwordTarget.value
    
    // Check if field is empty
    if (value === '') {
      this.showError(this.passwordTarget, "Password is required")
      this.hidePasswordRequirements()
      return false
    }
    
    // Build array of unmet requirements
    const errors = []
    
    // Minimum length check (matches Devise config)
    if (value.length < 8) {
      errors.push("at least 8 characters")
    }
    
    // Uppercase letter requirement
    if (!/[A-Z]/.test(value)) {
      errors.push("one uppercase letter")
    }
    
    if (!/[a-z]/.test(value)) {
      errors.push("one lowercase letter")
    }
    
    if (!/[0-9]/.test(value)) {
      errors.push("one number")
    }
    
    if (!/[^A-Za-z0-9]/.test(value)) {
      errors.push("one special character")
    }
    
    if (errors.length > 0) {
      this.showError(this.passwordTarget, `Password must include ${errors.join(', ')}`)
      return false
    }
    
    this.clearError(this.passwordTarget)
    this.hidePasswordRequirements()
    
    // Re-validate password confirmation if it has a value
    if (this.hasPasswordConfirmationTarget && this.passwordConfirmationTarget.value) {
      this.validatePasswordConfirmation()
    }
    
    return true
  }

  validatePasswordConfirmation() {
    const password = this.passwordTarget.value
    const confirmation = this.passwordConfirmationTarget.value
    
    if (confirmation === '') {
      this.showError(this.passwordConfirmationTarget, "Password confirmation is required")
      return false
    }
    
    if (password !== confirmation) {
      this.showError(this.passwordConfirmationTarget, "Passwords don't match")
      return false
    }
    
    this.clearError(this.passwordConfirmationTarget)
    return true
  }

  validateCheckboxes() {
    if (!this.hasTermsCheckboxTarget || !this.hasPrivacyCheckboxTarget) {
      return true // Skip validation for invited users
    }

    const termsAccepted = this.termsCheckboxTarget.checked
    const privacyAccepted = this.privacyCheckboxTarget.checked
    
    if (!termsAccepted || !privacyAccepted) {
      this.updateSubmitButton(false)
      return false
    }
    
    this.updateSubmitButton(true)
    return true
  }

  showPasswordRequirements() {
    const parent = this.passwordTarget.parentElement.parentElement
    let reqDiv = parent.querySelector('.password-requirements')
    
    if (!reqDiv) {
      reqDiv = document.createElement('div')
      reqDiv.className = 'password-requirements mt-2 text-xs text-gray-600'
      reqDiv.innerHTML = `
        <p class="font-medium mb-1">Password must contain:</p>
        <ul class="list-disc list-inside space-y-0.5">
          <li data-req="length">At least 8 characters</li>
          <li data-req="uppercase">One uppercase letter</li>
          <li data-req="lowercase">One lowercase letter</li>
          <li data-req="number">One number</li>
          <li data-req="special">One special character</li>
        </ul>
      `
      parent.appendChild(reqDiv)
    }
    
    // Update requirements based on current value
    const value = this.passwordTarget.value
    const items = reqDiv.querySelectorAll('li')
    
    items.forEach(item => {
      const req = item.dataset.req
      let met = false
      
      switch(req) {
        case 'length':
          met = value.length >= 8
          break
        case 'uppercase':
          met = /[A-Z]/.test(value)
          break
        case 'lowercase':
          met = /[a-z]/.test(value)
          break
        case 'number':
          met = /[0-9]/.test(value)
          break
        case 'special':
          met = /[^A-Za-z0-9]/.test(value)
          break
      }
      
      if (met) {
        item.classList.add('text-green-600', 'line-through')
        item.classList.remove('text-gray-600')
      } else {
        item.classList.remove('text-green-600', 'line-through')
        item.classList.add('text-gray-600')
      }
    })
  }

  hidePasswordRequirements() {
    const parent = this.passwordTarget.parentElement.parentElement
    const reqDiv = parent.querySelector('.password-requirements')
    if (reqDiv) {
      reqDiv.remove()
    }
  }

  // Displays error message and applies error styling to a field
  // @param field - The input element that has an error
  // @param message - The error message to display
  showError(field, message) {
    // Remove any existing error first to avoid duplicates
    this.clearError(field)
    
    // Add error styling to field - using darker red for better visibility
    // These classes make the border red and maintain red on focus
    field.classList.add('border-red-500', 'focus:border-red-500', 'focus:ring-red-500')
    field.classList.remove('border-gray-300', 'focus:border-blue-500', 'focus:ring-blue-500')
    
    // Create error message element
    const errorDiv = document.createElement('p')
    errorDiv.className = 'mt-1 text-sm text-red-600 field-error'
    errorDiv.textContent = message
    // Append error message below the field
    field.parentElement.appendChild(errorDiv)
  }

  // Removes error styling and message from a field
  // Called when user starts typing to fix an error
  // @param field - The input element to clear errors from
  clearError(field) {
    // Remove red border styling
    field.classList.remove('border-red-500', 'focus:border-red-500', 'focus:ring-red-500')
    // Restore normal gray/blue border styling
    field.classList.add('border-gray-300', 'focus:border-blue-500', 'focus:ring-blue-500')
    
    // Remove error message element if it exists
    const errorDiv = field.parentElement.querySelector('.field-error')
    if (errorDiv) {
      errorDiv.remove()
    }
  }

  updateSubmitButton(enabled) {
    if (this.hasSubmitButtonTarget) {
      if (enabled) {
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      } else {
        this.submitButtonTarget.disabled = true
        this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
      }
    }
  }

  // Handles form submission with validation
  // Prevents submission if any validation fails
  // Connected via data-action="submit->registration-validation#handleSubmit"
  handleSubmit(event) {
    // Prevent default form submission
    event.preventDefault()
    
    // Validate all fields
    // Use pattern: isValid = validate() && isValid
    // This ensures all validations run (not short-circuited)
    let isValid = true
    
    // Validate first name if present
    if (this.hasFirstNameTarget) {
      isValid = this.validateFirstName() && isValid
    }
    
    if (this.hasLastNameTarget) {
      isValid = this.validateLastName() && isValid
    }
    
    if (this.hasEmailTarget && !this.emailTarget.readOnly) {
      isValid = this.validateEmail() && isValid
    }
    
    if (this.hasPasswordTarget) {
      isValid = this.validatePassword() && isValid
    }
    
    if (this.hasPasswordConfirmationTarget) {
      isValid = this.validatePasswordConfirmation() && isValid
    }
    
    if (this.hasTermsCheckboxTarget && this.hasPrivacyCheckboxTarget) {
      isValid = this.validateCheckboxes() && isValid
      
      if (!this.termsCheckboxTarget.checked) {
        const termsLabel = this.termsCheckboxTarget.parentElement.parentElement
        termsLabel.classList.add('text-red-600')
        setTimeout(() => termsLabel.classList.remove('text-red-600'), 3000)
      }
      
      if (!this.privacyCheckboxTarget.checked) {
        const privacyLabel = this.privacyCheckboxTarget.parentElement.parentElement
        privacyLabel.classList.add('text-red-600')
        setTimeout(() => privacyLabel.classList.remove('text-red-600'), 3000)
      }
    }
    
    if (isValid) {
      event.target.submit()
    }
  }
}