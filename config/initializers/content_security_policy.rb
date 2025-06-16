# Be sure to restart your server when you modify this file.

# Content Security Policy (CSP) configuration for Rails application
# Helps prevent XSS, clickjacking, and other code injection attacks

Rails.application.configure do
  config.content_security_policy do |policy|
    # Default source for all content types
    policy.default_src :self, :https

    # Scripts: Allow self, CDNs, and inline scripts (for Rails UJS)
    script_sources = [ :self, :https, :unsafe_inline, "https://cdn.jsdelivr.net", "https://unpkg.com" ]
    script_sources << "https://ga.jspm.io" if Rails.env.development?
    policy.script_src(*script_sources)

    # Styles: Allow self, inline styles (for Tailwind), and data URIs
    policy.style_src :self,
                     :https,
                     :unsafe_inline,  # Required for Tailwind CSS
                     "https://cdn.jsdelivr.net",
                     "https://fonts.googleapis.com"

    # Images: Allow from anywhere (for user uploads, gravatar, etc)
    policy.img_src :self,
                   :https,
                   :data,  # For inline images
                   "https://www.gravatar.com",
                   "https://*.stripe.com"  # Stripe images

    # Fonts: Allow self and Google Fonts
    policy.font_src :self,
                    :https,
                    :data,
                    "https://fonts.gstatic.com"

    # Media: Audio and video sources
    policy.media_src :self, :https

    # Objects: Disallow plugins like Flash
    policy.object_src :none

    # Frames: Allow Stripe checkout and prevent clickjacking
    policy.frame_src :self,
                     "https://checkout.stripe.com",
                     "https://js.stripe.com",
                     "https://hooks.stripe.com"

    # Frame ancestors: Prevent clickjacking
    policy.frame_ancestors :none

    # Form actions: Where forms can submit
    policy.form_action :self

    # Base URI: Restrict <base> tag
    policy.base_uri :self

    # Connect sources: XHR, WebSocket, EventSource
    connect_sources = [ :self, :https, "https://api.stripe.com", "wss://*.stripe.com" ]
    if Rails.env.development?
      connect_sources += [ "http://localhost:*", "ws://localhost:*" ]
    end
    policy.connect_src(*connect_sources)

    # Worker sources: Service workers, shared workers
    policy.worker_src :self, :blob

    # Manifest source
    policy.manifest_src :self

    # Upgrade insecure requests in production
    policy.upgrade_insecure_requests true if Rails.env.production?

    # Report violations to CSP endpoint (if configured)
    if Rails.env.production? && ENV["CSP_REPORT_URI"].present?
      policy.report_uri ENV["CSP_REPORT_URI"]
    elsif Rails.env.development?
      # In development, report to console
      policy.report_uri "/csp_violation_reports"
    end
  end

  # Generate session nonces for per-request inline scripts
  config.content_security_policy_nonce_generator = ->(request) {
    SecureRandom.base64(16)
  }

  # Use nonce for style tags (required for some Rails helpers)
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report only mode in development (logs violations without blocking)
  config.content_security_policy_report_only = Rails.env.development?
end

# Configure CSP for specific controllers/actions if needed
# Example:
# Rails.application.config.content_security_policy_mappings = {
#   # Allow unsafe-eval for specific admin pages that need it
#   "admin/dashboard#analytics" => {
#     script_src: :self, :unsafe_inline, :unsafe_eval
#   }
# }
