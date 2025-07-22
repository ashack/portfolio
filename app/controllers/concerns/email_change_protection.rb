# EmailChangeProtection Concern
#
# OVERVIEW:
# This security-critical concern prevents unauthorized email address changes across
# the entire triple-track SaaS system. It intercepts any attempt to modify email
# addresses through standard form submissions and enforces the secure EmailChangeRequest
# workflow instead.
#
# SECURITY PURPOSE:
# - Prevent account takeover attacks via unauthorized email changes
# - Enforce secure email change verification workflow
# - Block direct parameter manipulation of email fields
# - Provide comprehensive audit logging of email change attempts
# - Protect against both accidental and malicious email modifications
#
# THREAT PROTECTION:
# This concern protects against several attack vectors:
# 1. CSRF attacks attempting to change email addresses
# 2. Parameter pollution attacks targeting email fields
# 3. Session hijacking attempts to modify account email
# 4. Admin impersonation attacks that change user emails
# 5. Direct form manipulation by authenticated users
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# This concern protects users across all tracks of the SaaS system:
# 1. DIRECT USERS: Prevents unauthorized changes to individual account emails
# 2. TEAM MEMBERS: Protects team member email addresses from tampering
# 3. ENTERPRISE USERS: Secures enterprise user email addresses
# 4. ADMIN USERS: Even protects admin accounts from email manipulation
#
# SECURE EMAIL CHANGE WORKFLOW:
# Instead of allowing direct email changes, the system enforces:
# 1. User initiates email change request through dedicated interface
# 2. EmailChangeRequest record created with new email and verification token
# 3. Verification email sent to new email address
# 4. User clicks verification link to confirm ownership
# 5. System validates request and updates email if valid
# 6. Old email notified of the change for security awareness
#
# SPECIAL PERMISSIONS:
# - Super Admin users can change their own email directly (with audit logging)
# - All other users (including site admins) must use the secure workflow
# - Even super admin direct changes are logged for security auditing
#
# EXTERNAL DEPENDENCIES:
# - AuditLogService: For security event logging and audit trails
# - Rails parameter filtering: For secure parameter handling
# - EmailChangeRequest model: For the secure change workflow
#
# USAGE EXAMPLES:
# 1. Include in user-facing controllers:
#    class Users::ProfileController < ApplicationController
#      include EmailChangeProtection
#    end
#
# 2. Include in admin controllers:
#    class Admin::UsersController < ApplicationController
#      include EmailChangeProtection
#    end
#
# 3. Global inclusion for comprehensive protection:
#    class ApplicationController < ActionController::Base
#      include EmailChangeProtection
#    end
#
# BUSINESS LOGIC:
# - All email change attempts are intercepted and analyzed
# - Legitimate changes are redirected to secure workflow
# - Malicious attempts are blocked and logged
# - User experience maintained through informative flash messages
# - Security events logged for incident response
#
# COMPLIANCE CONSIDERATIONS:
# - Supports security compliance frameworks requiring email change verification
# - Provides audit trails for security incident investigations  
# - Enables compliance with data protection regulations
# - Supports enterprise security requirements for email address integrity
module EmailChangeProtection
  extend ActiveSupport::Concern

  included do
    # Check for unauthorized email change attempts in params before any action
    # This early interception prevents email changes from being processed
    # by standard Rails parameter handling
    before_action :check_for_email_change_attempt, if: :user_params_present?
  end

  private

  # Main protection method - analyzes and handles email change attempts
  #
  # PROTECTION FLOW:
  # 1. Check if parameters contain email modification attempt
  # 2. Special handling for super admin users (allowed with logging)
  # 3. Block unauthorized attempts and remove email from parameters
  # 4. Log security event for audit and monitoring
  # 5. Inform user of security requirement through flash message
  #
  # SECURITY LAYERS:
  # - Parameter analysis before processing
  # - Email parameter removal to prevent accidental processing
  # - Comprehensive logging for security monitoring
  # - User notification without exposing security details
  #
  # SUPER ADMIN EXCEPTION:
  # Super admins can change their own email directly for operational needs,
  # but all such changes are logged for security audit purposes.
  def check_for_email_change_attempt
    return unless params_contain_email_change?

    # Allow super admins to change their own email directly
    if current_user&.super_admin?
      # Log the super admin email change for audit purposes
      log_super_admin_email_change
      return # Don't block the change
    end

    # Log the attempt
    log_email_change_attempt

    # Remove email from params to prevent processing
    remove_email_from_params

    # Add a flash message to inform user
    flash.now[:alert] = "Email changes must be requested through the email change request system for security reasons."
  end

  # Detects if request parameters contain an email change attempt
  #
  # DETECTION LOGIC:
  # 1. Checks for presence of user parameter objects
  # 2. Validates parameter structure is ActionController::Parameters
  # 3. Compares provided email with current user's email
  # 4. Returns true if email field present and different from current
  #
  # PARAMETER SOURCES:
  # - params[:user] (standard Rails convention)
  # - params[controller_singular] (RESTful controller conventions)
  #
  # SECURITY NOTE: This method is conservative and treats any email
  # parameter difference as a potential change attempt to err on the
  # side of security.
  #
  # @return [Boolean] true if parameters contain email change attempt
  def params_contain_email_change?
    return false unless user_params_present?

    user_params = params[:user] || params[controller_name.singularize.to_sym]
    return false unless user_params.is_a?(ActionController::Parameters)

    # Check if email is present and different from current user's email
    user_params[:email].present? &&
      current_user &&
      user_params[:email] != current_user.email
  end

  # Checks if user-related parameters are present in the request
  #
  # PARAMETER PATTERNS CHECKED:
  # - params[:user] - Standard Rails user parameter convention
  # - params[controller_singular] - RESTful resource parameter convention
  #
  # Used as a performance optimization to avoid unnecessary processing
  # when no user parameters are present in the request.
  #
  # @return [Boolean] true if user parameters are present
  def user_params_present?
    params[:user].present? || params[controller_name.singularize.to_sym].present?
  end

  # Removes email parameters from request to prevent processing
  #
  # PARAMETERS REMOVED:
  # - :email - Primary email field
  # - :unconfirmed_email - Devise email confirmation field
  #
  # REMOVAL LOCATIONS:
  # - params[:user] - Standard Rails user parameters
  # - params[controller_singular] - RESTful resource parameters
  #
  # SECURITY PURPOSE: Even after detection and logging, email parameters
  # are removed to ensure they cannot be processed by subsequent controller
  # actions or form handling code.
  #
  # This creates a defense-in-depth approach where blocked attempts
  # cannot accidentally succeed through parameter processing.
  def remove_email_from_params
    if params[:user].present?
      params[:user].delete(:email)
      params[:user].delete(:unconfirmed_email)
    end

    singular_key = controller_name.singularize.to_sym
    if params[singular_key].present?
      params[singular_key].delete(:email)
      params[singular_key].delete(:unconfirmed_email)
    end
  end

  # Logs blocked email change attempts for security monitoring
  #
  # LOGGING COMPONENTS:
  # 1. Rails logger with SECURITY tag for immediate alerting
  # 2. AuditLogService for structured database logging
  # 3. Comprehensive request metadata for forensic analysis
  #
  # LOGGED INFORMATION:
  # - User attempting the change (ID and current email)
  # - Attempted new email address
  # - Request context (controller, action, IP, user agent)
  # - Blocking reason for compliance documentation
  #
  # SECURITY MONITORING:
  # These logs can trigger security alerts for:
  # - Multiple failed email change attempts
  # - Attempts from suspicious IP addresses
  # - Unusual patterns indicating potential account compromise
  #
  # COMPLIANCE VALUE:
  # Provides audit trail required by security frameworks and
  # compliance standards for unauthorized access attempt tracking.
  def log_email_change_attempt
    user_params = params[:user] || params[controller_name.singularize.to_sym]
    attempted_email = user_params[:email]

    Rails.logger.warn "[SECURITY] Email change attempt blocked in #{controller_name}##{action_name}"
    Rails.logger.warn "[SECURITY] User: #{current_user&.id} (#{current_user&.email})"
    Rails.logger.warn "[SECURITY] Attempted email: #{attempted_email}"
    Rails.logger.warn "[SECURITY] IP: #{request.remote_ip}"
    Rails.logger.warn "[SECURITY] User Agent: #{request.user_agent}"

    # Create audit log for security tracking
    if current_user
      AuditLogService.log_security_event(
        admin_user: current_user, # User attempting the change
        target_user: current_user, # Same user since it's self-modification
        event_type: "email_change_attempt_blocked",
        details: {
          attempted_email: attempted_email,
          current_email: current_user.email,
          controller: controller_name,
          action: action_name,
          blocked_reason: "Direct email change not allowed"
        },
        request: request
      )
    end
  end

  # Logs authorized super admin email changes for audit compliance
  #
  # AUDIT REQUIREMENTS:
  # Even authorized email changes by super admins must be logged
  # for complete audit trails and compliance documentation.
  #
  # LOGGED INFORMATION:
  # - Super admin user performing the change
  # - Old email address for historical tracking
  # - New email address being set
  # - Request context for verification
  # - Special notation of super admin privilege use
  #
  # COMPLIANCE PURPOSE:
  # - Demonstrates proper oversight of privileged operations
  # - Provides audit trail for super admin activity reviews
  # - Supports compliance with administrative access monitoring
  # - Enables detection of potential super admin account compromise
  #
  # SECURITY MONITORING:
  # These logs help identify:
  # - Unauthorized super admin account usage
  # - Unusual super admin activity patterns
  # - Potential privilege escalation attempts
  def log_super_admin_email_change
    user_params = params[:user] || params[controller_name.singularize.to_sym]
    new_email = user_params[:email]
    old_email = current_user.email

    Rails.logger.info "[AUDIT] Super admin email change in #{controller_name}##{action_name}"
    Rails.logger.info "[AUDIT] User: #{current_user.id} (#{old_email})"
    Rails.logger.info "[AUDIT] New email: #{new_email}"
    Rails.logger.info "[AUDIT] IP: #{request.remote_ip}"

    # Create audit log for tracking
    AuditLogService.log_security_event(
      admin_user: current_user,
      target_user: current_user,
      event_type: "super_admin_email_change",
      details: {
        old_email: old_email,
        new_email: new_email,
        controller: controller_name,
        action: action_name,
        note: "Super admin direct email change"
      },
      request: request
    )
  end
end
