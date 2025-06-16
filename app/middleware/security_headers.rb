# Security Headers Middleware
# Adds comprehensive security headers to all responses
class SecurityHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Add security headers
    headers["X-Frame-Options"] = "DENY"
    headers["X-Content-Type-Options"] = "nosniff"
    headers["X-XSS-Protection"] = "1; mode=block"
    headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    headers["Permissions-Policy"] = permissions_policy

    # Only set HSTS in production
    if Rails.env.production?
      headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"
    end

    # Remove headers that might leak information
    headers.delete("X-Powered-By")
    headers.delete("Server")

    [ status, headers, response ]
  end

  private

  def permissions_policy
    [
      "accelerometer=()",
      "camera=()",
      "geolocation=()",
      "gyroscope=()",
      "magnetometer=()",
      "microphone=()",
      "payment=(self)",
      "usb=()"
    ].join(", ")
  end
end
