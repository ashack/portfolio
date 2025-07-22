# Enhanced CSRF Protection Configuration
# This file configures additional security measures for Cross-Site Request Forgery protection

Rails.application.configure do
  # Configure CSRF token generation
  # Use session-based CSRF tokens for better compatibility
  config.action_controller.per_form_csrf_tokens = false

  # Verify the origin of requests in addition to CSRF tokens
  # Set to false in development/test only
  config.action_controller.forgery_protection_origin_check = Rails.env.production?

  # Log CSRF failures for security monitoring
  config.action_controller.log_warning_on_csrf_failure = true
  
  # Allow same-origin requests in development
  if Rails.env.development?
    config.action_controller.forgery_protection_origin_check = false
  end
end

# Security note: CSRF tokens are automatically included in:
# - form_with helper (default)
# - form_for helper
# - form_tag helper
# - button_to helper
# - link_to helper with method: other than :get
# - Remote forms (data-remote="true")
# - Turbo forms (default behavior)

# For manual AJAX requests, use the csrf_controller.js utility or include:
# - X-CSRF-Token header with token from meta tag
# - authenticity_token parameter in request body
