// Configure Turbo to properly handle CSRF tokens for internal navigation
import { Turbo } from "@hotwired/turbo-rails"

// Ensure CSRF tokens are included in all Turbo requests
document.addEventListener("turbo:before-fetch-request", (event) => {
  const token = document.querySelector('meta[name="csrf-token"]')?.content
  
  if (token) {
    // Ensure the X-CSRF-Token header is set
    event.detail.fetchOptions.headers["X-CSRF-Token"] = token
  }
})

// Handle form submissions to ensure CSRF token is included
document.addEventListener("turbo:submit-start", (event) => {
  const form = event.target
  const token = document.querySelector('meta[name="csrf-token"]')?.content
  
  if (token) {
    // Check if authenticity_token field exists
    let tokenField = form.querySelector('input[name="authenticity_token"]')
    
    if (!tokenField) {
      // Create hidden field if it doesn't exist
      tokenField = document.createElement('input')
      tokenField.type = 'hidden'
      tokenField.name = 'authenticity_token'
      form.appendChild(tokenField)
    }
    
    // Update the token value
    tokenField.value = token
  }
})

// Handle CSRF token errors gracefully
document.addEventListener("turbo:fetch-request-error", async (event) => {
  if (event.detail.response.status === 422) {
    const responseText = await event.detail.response.text()
    
    if (responseText.includes("CSRF") || responseText.includes("authenticity")) {
      console.warn("CSRF token error detected, reloading page")
      
      // Prevent default error handling
      event.preventDefault()
      
      // Reload the page to get a fresh CSRF token
      window.location.reload()
    }
  }
})

console.log("Turbo CSRF protection configured")