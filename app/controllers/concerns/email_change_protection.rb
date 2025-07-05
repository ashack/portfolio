# EmailChangeProtection - Security concern to prevent unauthorized email changes
#
# This concern should be included in all controllers that handle user updates
# to ensure email changes can only happen through the approved EmailChangeRequest system
#
# SECURITY: Critical for preventing account takeover attacks
module EmailChangeProtection
  extend ActiveSupport::Concern

  included do
    # Check for unauthorized email change attempts in params
    before_action :check_for_email_change_attempt, if: :user_params_present?
  end

  private

  # Checks if user is attempting to change email through params
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

  # Check if params contain an email change attempt
  def params_contain_email_change?
    return false unless user_params_present?

    user_params = params[:user] || params[controller_name.singularize.to_sym]
    return false unless user_params.is_a?(ActionController::Parameters)

    # Check if email is present and different from current user's email
    user_params[:email].present? &&
      current_user &&
      user_params[:email] != current_user.email
  end

  # Check if user params are present
  def user_params_present?
    params[:user].present? || params[controller_name.singularize.to_sym].present?
  end

  # Remove email from params to prevent processing
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

  # Log email change attempt for security auditing
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

  # Log super admin email change for audit purposes
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
