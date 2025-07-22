# Controller for receiving Content Security Policy (CSP) violation reports
# Browsers automatically send POST requests here when CSP violations occur
# Used for security monitoring and debugging CSP configuration
class CspReportsController < ApplicationController
  # Skip CSRF token verification - CSP reports come from browser, not user forms
  skip_before_action :verify_authenticity_token
  # Allow public access - browsers send reports without authentication
  skip_before_action :authenticate_user!
  # Skip authorization - this is a webhook endpoint
  skip_after_action :verify_authorized

  # POST /csp_reports
  # Endpoint for browsers to report CSP violations
  # Called automatically by browsers when CSP rules are violated
  def create
    # Parse the JSON report sent by the browser
    report = JSON.parse(request.body.read)

    # Log violation details for security monitoring and debugging
    log_csp_violation(report["csp-report"])

    # In production, send violations to monitoring service for alerting
    if Rails.env.production?
      # Example: Send to error tracking service for security team
      # Honeybadger.notify("CSP Violation", context: report)
      # Bugsnag.notify("CSP Violation", report)
    end

    # Return 204 No Content as expected by browsers
    head :no_content
  rescue JSON::ParserError => e
    # Handle malformed reports gracefully
    Rails.logger.error "Invalid CSP report: #{e.message}"
    head :bad_request
  end

  private

  # Log CSP violation details for security monitoring
  # Extracts key information from browser violation report
  def log_csp_violation(report)
    return unless report

    # Log essential violation information
    Rails.logger.warn "[CSP Violation] #{report['violated-directive']}"
    Rails.logger.warn "  Document URI: #{report['document-uri']}"
    Rails.logger.warn "  Blocked URI: #{report['blocked-uri']}"
    # Optional fields that may not always be present
    Rails.logger.warn "  Line Number: #{report['line-number']}" if report["line-number"]
    Rails.logger.warn "  Source File: #{report['source-file']}" if report["source-file"]
    Rails.logger.warn "  Original Policy: #{report['original-policy']}"

    # In development, log full report for detailed debugging
    if Rails.env.development?
      Rails.logger.info "Full CSP Report: #{report.to_json}"
    end
  end
end
