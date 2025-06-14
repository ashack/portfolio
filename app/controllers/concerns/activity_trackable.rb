module ActivityTrackable
  extend ActiveSupport::Concern

  included do
    after_action :track_admin_activity, if: :should_track_activity?
  end

  private

  def should_track_activity?
    # Track activity for admin users and specific actions
    current_user&.admin? &&
    !devise_controller? &&
    trackable_action? &&
    request.format.html? # Only track HTML requests, not JSON/AJAX
  end

  def trackable_action?
    # Track state-changing actions (non-GET requests) and specific GET actions
    !request.get? || trackable_get_actions.include?(action_name)
  end

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

  def filtered_params
    # Filter sensitive parameters
    filter = ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
    filter.filter(params.to_unsafe_h)
  end

  # Helper methods for explicit activity tracking
  def track_user_action(action_type, target_user, details = {})
    AuditLogService.log(
      admin_user: current_user,
      target_user: target_user,
      action: action_type,
      details: details,
      request: request
    )
  end

  def track_team_action(action_type, team, details = {})
    AuditLogService.log_team_action(
      admin_user: current_user,
      team: team,
      action: action_type,
      details: details,
      request: request
    )
  end

  def track_system_action(action_type, details = {})
    AuditLogService.log_system_action(
      admin_user: current_user,
      action: action_type,
      details: details,
      request: request
    )
  end

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
