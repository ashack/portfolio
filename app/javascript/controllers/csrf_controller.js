import { Controller } from "@hotwired/stimulus"

// CSRF Protection Utility Controller
// Provides methods for handling CSRF tokens in AJAX requests
export default class extends Controller {
  connect() {
    console.log("CSRF protection controller connected")
  }

  // Get CSRF token from meta tag
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : null
  }

  // Get CSRF parameter name from meta tag
  getCSRFParam() {
    const param = document.querySelector('meta[name="csrf-param"]')
    return param ? param.getAttribute('content') : 'authenticity_token'
  }

  // Add CSRF token to form data
  addCSRFToFormData(formData) {
    const token = this.getCSRFToken()
    const param = this.getCSRFParam()
    
    if (token && param) {
      formData.append(param, token)
    }
    
    return formData
  }

  // Add CSRF token to headers for fetch requests
  getCSRFHeaders() {
    const token = this.getCSRFToken()
    
    if (token) {
      return {
        'X-CSRF-Token': token,
        'X-Requested-With': 'XMLHttpRequest'
      }
    }
    
    return {
      'X-Requested-With': 'XMLHttpRequest'
    }
  }

  // Helper method for making secure AJAX requests
  async secureRequest(url, options = {}) {
    const defaultOptions = {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...this.getCSRFHeaders()
      },
      credentials: 'same-origin'
    }

    const mergedOptions = {
      ...defaultOptions,
      ...options,
      headers: {
        ...defaultOptions.headers,
        ...options.headers
      }
    }

    try {
      const response = await fetch(url, mergedOptions)
      
      if (response.status === 403) {
        const data = await response.json()
        if (data.error && data.error.includes('CSRF')) {
          console.error('CSRF token verification failed')
          window.location.reload() // Reload to get fresh CSRF token
          return null
        }
      }
      
      return response
    } catch (error) {
      console.error('Request failed:', error)
      throw error
    }
  }

  // Form submission with CSRF protection
  submitFormSecurely(form, options = {}) {
    const formData = new FormData(form)
    this.addCSRFToFormData(formData)
    
    const submitOptions = {
      method: form.method || 'POST',
      body: formData,
      headers: this.getCSRFHeaders(),
      ...options
    }
    
    return this.secureRequest(form.action, submitOptions)
  }
}