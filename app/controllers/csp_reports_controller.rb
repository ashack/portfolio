class CspReportsController < ApplicationController
  # Skip CSRF for CSP violation reports (they come from browser, not forms)
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized
  
  def create
    # Parse the CSP violation report
    report = JSON.parse(request.body.read)
    
    # Log the violation for monitoring
    log_csp_violation(report['csp-report'])
    
    # In production, you might want to send these to a monitoring service
    if Rails.env.production?
      # Example: Send to error tracking service
      # Honeybadger.notify("CSP Violation", context: report)
    end
    
    head :no_content
  rescue JSON::ParserError => e
    Rails.logger.error "Invalid CSP report: #{e.message}"
    head :bad_request
  end
  
  private
  
  def log_csp_violation(report)
    return unless report
    
    Rails.logger.warn "[CSP Violation] #{report['violated-directive']}"
    Rails.logger.warn "  Document URI: #{report['document-uri']}"
    Rails.logger.warn "  Blocked URI: #{report['blocked-uri']}"
    Rails.logger.warn "  Line Number: #{report['line-number']}" if report['line-number']
    Rails.logger.warn "  Source File: #{report['source-file']}" if report['source-file']
    Rails.logger.warn "  Original Policy: #{report['original-policy']}"
    
    # Track violations in development for debugging
    if Rails.env.development?
      Rails.logger.info "Full CSP Report: #{report.to_json}"
    end
  end
end