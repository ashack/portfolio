# Enhanced CSRF Protection Configuration
# This file configures additional security measures for Cross-Site Request Forgery protection

Rails.application.configure do
  # Configure CSRF token generation
  # Use a random per-session CSRF token for maximum security
  config.action_controller.per_form_csrf_tokens = true

  # Verify the origin of requests in addition to CSRF tokens
  config.action_controller.forgery_protection_origin_check = true

  # Log CSRF failures for security monitoring
  config.action_controller.log_warning_on_csrf_failure = true
end

# Custom CSRF failure handling
class ActionController::Base
  private

  def handle_unverified_request
    # Log CSRF failures for security monitoring
    Rails.logger.warn "[SECURITY] CSRF verification failed for #{request.remote_ip} - #{request.user_agent}"
    Rails.logger.warn "[SECURITY] Request: #{request.method} #{request.path}"
    Rails.logger.warn "[SECURITY] Referrer: #{request.referrer}" if request.referrer

    # Call the default behavior
    super
  end
end

# Additional security headers for CSRF protection
# Note: Rack::Attack is loaded in config/application.rb

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
