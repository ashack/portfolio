# ActivityTrackable Concern
#
# OVERVIEW:
# This concern provides comprehensive admin activity tracking functionality for controllers.
# It automatically tracks admin actions in the background to provide detailed audit trails
# without impacting application performance or user experience.
#
# PURPOSE:
# - Provide detailed audit logs for all admin activities
# - Support compliance and security monitoring requirements
# - Track both automatic and manual admin actions across all user types
# - Ensure non-blocking activity logging with error resilience
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# This concern works across all three user tracks in the SaaS application:
# 1. SUPER ADMIN: Tracks platform-wide administrative actions
# 2. SITE ADMIN: Tracks support and user management activities
# 3. TEAM ADMIN: Tracks team-specific administrative actions
# 4. ENTERPRISE ADMIN: Tracks enterprise-specific administrative actions
#
# SECURITY CONSIDERATIONS:
# - Only tracks admin users (super_admin?, site_admin?, team_admin?, enterprise_admin?)
# - Filters sensitive parameters from logs
# - Uses background jobs to prevent timing attacks
# - Includes comprehensive request metadata for forensic analysis
# - Implements graceful error handling to prevent application disruption
#
# PERFORMANCE:
# - Uses asynchronous background jobs (TrackAdminActivityJob)
# - Minimal overhead on request processing
# - Efficient filtering of trackable vs non-trackable actions
# - Only processes HTML requests to reduce noise
#
# EXTERNAL DEPENDENCIES:
# - TrackAdminActivityJob: Background job for async processing
# - AuditLogService: Service for structured audit logging
# - Rails.cache: For activity caching and deduplication
# - ActionDispatch::Http::ParameterFilter: For sensitive data filtering
#
# USAGE EXAMPLES:
# 1. Automatic tracking (included in admin base controllers):
#    class Admin::SuperAdminController < ApplicationController
#      include ActivityTrackable
#    end
#
# 2. Manual tracking in controller actions:
#    def update_user_status
#      # ... business logic ...
#      track_user_action("status_change", @user, { from: @old_status, to: @new_status })
#    end
#
# 3. Team-specific tracking:
#    def remove_team_member
#      # ... business logic ...
#      track_team_action("member_removed", @team, { removed_user_id: @user.id })
#    end
#
# BUSINESS LOGIC:
# - Admin activities are tracked automatically based on user role and action type
# - Sensitive parameters (passwords, tokens) are automatically filtered
# - Failed tracking attempts don't break the application flow
# - Provides both automatic tracking and helper methods for explicit tracking
# - Supports different tracking contexts (user, team, system, security events)
#
module ActivityTrackable
  extend ActiveSupport::Concern

  included do
    # Track admin activity after each action completes
    # Using after_action ensures the action completed successfully
    # The condition check prevents unnecessary job queuing
    after_action :track_admin_activity, if: :should_track_activity?
  end

  private

  # Determines whether the current request should be tracked
  # 
  # TRACKING CRITERIA:
  # 1. User must be an admin (any admin type in the triple-track system)
  # 2. Must not be a Devise authentication controller (login/logout/registration)
  # 3. Must be a trackable action (state-changing or explicitly tracked GET actions)
  # 4. Must be an HTML request (excludes API calls and AJAX requests)
  #
  # SECURITY NOTE: Only HTML requests are tracked to focus on user interface
  # actions and reduce log volume from API calls and background requests.
  #
  # @return [Boolean] true if the current request should be tracked
  def should_track_activity?
    # Track activity for admin users and specific actions
    current_user&.admin? &&
    !devise_controller? &&
    trackable_action? &&
    request.format.html? # Only track HTML requests, not JSON/AJAX
  end

  # Determines if the current action should be tracked based on HTTP method and action name
  #
  # TRACKING POLICY:
  # - All non-GET requests (POST, PUT, PATCH, DELETE) are tracked as they modify state
  # - Specific GET actions that access sensitive data or perform admin functions
  # - Excludes regular read-only GET actions to reduce log volume
  #
  # @return [Boolean] true if the action should be tracked
  def trackable_action?
    # Track state-changing actions (non-GET requests) and specific GET actions
    !request.get? || trackable_get_actions.include?(action_name)
  end

  # Defines GET actions that should be tracked despite being read-only
  #
  # TRACKED GET ACTIONS:
  # - impersonate: User impersonation for support/debugging
  # - show_admin_dashboard: Admin dashboard access
  # - view_sensitive_data: Access to sensitive user or system information
  # - download_export: Data export operations
  # - access_system_settings: System configuration access
  #
  # These actions are tracked because they:
  # 1. Access sensitive information
  # 2. Perform privileged operations
  # 3. Are important for audit and compliance requirements
  #
  # @return [Array<String>] list of GET action names to track
  def trackable_get_actions
    # Specific GET actions that should be tracked
    %w[
      impersonate
      show_admin_dashboard
      view_sensitive_data
      download_export
      access_system_settings
    ]
  end

  # Main activity tracking method - queues background job with activity data
  #
  # PERFORMANCE CONSIDERATIONS:
  # - Uses background job to avoid blocking the request/response cycle
  # - Builds comprehensive activity data for forensic analysis
  # - Implements graceful error handling to prevent application disruption
  #
  # ERROR HANDLING:
  # - Failed tracking attempts are logged but don't break the application
  # - Includes full stack trace for debugging tracking issues
  # - Ensures user experience is never impacted by logging failures
  #
  # SECURITY BENEFITS:
  # - Creates immutable audit trail in background
  # - Prevents timing attacks by not blocking on database writes
  # - Ensures consistent logging regardless of application load
  def track_admin_activity
    return unless current_user

    activity_data = build_activity_data

    # Log the activity asynchronously to avoid impacting response time
    TrackAdminActivityJob.perform_later(
      admin_user_id: current_user.id,
      activity_data: activity_data
    )
  rescue => e
    # Don't let activity tracking break the application
    Rails.logger.error "Failed to track admin activity: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  # Builds comprehensive activity data for audit logging
  #
  # COLLECTED DATA:
  # - Request context: controller, action, method, path
  # - Security context: IP address, user agent, referer
  # - Session context: session ID, request ID
  # - Parameters: filtered to remove sensitive data
  # - Timing: ISO8601 timestamp for precise tracking
  #
  # PRIVACY AND SECURITY:
  # - Parameters are filtered to remove passwords, tokens, etc.
  # - Uses public session ID (not internal session data)
  # - Includes request ID for correlation with other logs
  #
  # @return [Hash] comprehensive activity data for logging
  def build_activity_data
    {
      controller: controller_name,
      action: action_name,
      method: request.method,
      path: request.path,
      params: filtered_params,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer,
      timestamp: Time.current.iso8601,
      session_id: session.id&.public_id,
      request_id: request.request_id
    }
  end

  # Filters sensitive parameters from request params before logging
  #
  # FILTERED PARAMETERS:
  # Uses Rails' built-in parameter filtering configuration to remove:
  # - Passwords and password confirmations
  # - Authentication tokens and API keys
  # - Credit card numbers and sensitive financial data
  # - Personal identification numbers
  # - Any custom parameters defined in filter_parameters config
  #
  # SECURITY NOTE: This prevents sensitive data from appearing in audit logs
  # while preserving non-sensitive parameters for debugging and analysis.
  #
  # @return [Hash] filtered parameters safe for logging
  def filtered_params
    # Filter sensitive parameters
    filter = ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
    filter.filter(params.to_unsafe_h)
  end

  # MANUAL TRACKING HELPER METHODS
  # These methods allow controllers to explicitly track specific actions
  # beyond the automatic tracking provided by the after_action callback.

  # Tracks actions performed on a specific user
  #
  # USAGE EXAMPLES:
  # - User status changes (activate, deactivate, lock)
  # - Profile updates performed by admin
  # - Password resets initiated by admin
  # - User deletion or suspension
  #
  # @param action_type [String] the type of action performed
  # @param target_user [User] the user being acted upon
  # @param details [Hash] additional context and details
  def track_user_action(action_type, target_user, details = {})
    AuditLogService.log(
      admin_user: current_user,
      target_user: target_user,
      action: action_type,
      details: details,
      request: request
    )
  end

  # Tracks actions performed on a team
  #
  # USAGE EXAMPLES:
  # - Team creation or deletion
  # - Team member addition or removal
  # - Team settings changes
  # - Team subscription changes
  #
  # TRIPLE-TRACK INTEGRATION:
  # This is specifically for team-related admin actions in the team track
  # of the triple-track SaaS system.
  #
  # @param action_type [String] the type of action performed
  # @param team [Team] the team being acted upon
  # @param details [Hash] additional context and details
  def track_team_action(action_type, team, details = {})
    AuditLogService.log_team_action(
      admin_user: current_user,
      team: team,
      action: action_type,
      details: details,
      request: request
    )
  end

  # Tracks system-wide administrative actions
  #
  # USAGE EXAMPLES:
  # - System configuration changes
  # - Platform-wide feature toggles
  # - Database maintenance operations
  # - System backup or restore operations
  #
  # @param action_type [String] the type of action performed
  # @param details [Hash] additional context and details
  def track_system_action(action_type, details = {})
    AuditLogService.log_system_action(
      admin_user: current_user,
      action: action_type,
      details: details,
      request: request
    )
  end

  # Tracks security-related events and incidents
  #
  # USAGE EXAMPLES:
  # - Failed login attempts
  # - Suspicious activity detection
  # - Account lockouts
  # - Security policy violations
  # - Unauthorized access attempts
  #
  # SECURITY COMPLIANCE:
  # This method is critical for security incident response and compliance
  # with security frameworks that require detailed security event logging.
  #
  # @param event_type [String] the type of security event
  # @param target_user [User] the user involved in the security event
  # @param details [Hash] additional context and security-relevant details
  def track_security_event(event_type, target_user, details = {})
    AuditLogService.log_security_event(
      admin_user: current_user,
      target_user: target_user,
      event_type: event_type,
      details: details,
      request: request
    )
  end
end
