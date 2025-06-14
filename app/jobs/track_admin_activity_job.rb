class TrackAdminActivityJob < ApplicationJob
  queue_as :default

  # Retry failed jobs with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(admin_user_id:, activity_data:)
    admin_user = User.find_by(id: admin_user_id)
    return unless admin_user

    # Create detailed activity log
    AdminActivityLog.create!(
      admin_user: admin_user,
      controller: activity_data[:controller],
      action: activity_data[:action],
      method: activity_data[:method],
      path: activity_data[:path],
      params: activity_data[:params],
      ip_address: activity_data[:ip_address],
      user_agent: activity_data[:user_agent],
      referer: activity_data[:referer],
      session_id: activity_data[:session_id],
      request_id: activity_data[:request_id],
      timestamp: Time.parse(activity_data[:timestamp])
    )

    # Also create a simplified audit log entry for critical actions
    if critical_action?(activity_data)
      create_audit_log_entry(admin_user, activity_data)
    end

    # Check for suspicious activity patterns
    detect_suspicious_activity(admin_user, activity_data)

  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "Admin user #{admin_user_id} not found for activity tracking"
  rescue => e
    Rails.logger.error "Failed to track admin activity: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Re-raise to trigger retry mechanism
  end

  private

  def critical_action?(activity_data)
    critical_controllers = %w[admin users teams]
    critical_actions = %w[create update destroy promote demote impersonate]

    critical_controllers.include?(activity_data[:controller]) &&
    critical_actions.include?(activity_data[:action])
  end

  def create_audit_log_entry(admin_user, activity_data)
    # Map controller/action to audit log action type
    audit_action = map_to_audit_action(activity_data[:controller], activity_data[:action])
    return unless audit_action

    # Determine target user from params if available
    target_user = find_target_user(activity_data[:params])
    target_user ||= admin_user # Fallback to self-referential

    AuditLogService.log(
      admin_user: admin_user,
      target_user: target_user,
      action: audit_action,
      details: {
        controller: activity_data[:controller],
        action: activity_data[:action],
        path: activity_data[:path],
        timestamp: activity_data[:timestamp]
      }
    )
  end

  def map_to_audit_action(controller, action)
    case "#{controller}##{action}"
    when "admin/super/users#update"
      "user_update"
    when "admin/super/users#destroy"
      "user_delete"
    when "admin/super/users#impersonate"
      "impersonate"
    when "admin/super/users#set_status"
      "status_change"
    when "teams#create"
      "team_create"
    when "teams#update"
      "team_update"
    when "teams#destroy"
      "team_delete"
    else
      nil # Not a critical action for audit log
    end
  end

  def find_target_user(params)
    # Try to find target user from various parameter patterns
    user_id = params["id"] || params["user_id"] || params.dig("user", "id")
    return nil unless user_id

    User.find_by(id: user_id)
  end

  def detect_suspicious_activity(admin_user, activity_data)
    # Check for rapid successive actions (potential automation/attack)
    recent_activities = AdminActivityLog.where(admin_user: admin_user)
                                       .where("created_at > ?", 1.minute.ago)
                                       .count

    if recent_activities > 20 # More than 20 actions in 1 minute
      Rails.logger.warn "[SECURITY] Suspicious rapid activity detected for admin #{admin_user.email}"
      Rails.logger.warn "[SECURITY] #{recent_activities} actions in the last minute from IP #{activity_data[:ip_address]}"

      # Create security alert
      AuditLogService.log_security_event(
        admin_user: admin_user,
        target_user: admin_user,
        event_type: "security_lock",
        details: {
          reason: "rapid_successive_actions",
          action_count: recent_activities,
          timeframe: "1_minute",
          ip_address: activity_data[:ip_address]
        }
      )
    end

    # Check for unusual IP addresses
    usual_ips = AdminActivityLog.where(admin_user: admin_user)
                               .where("created_at > ?", 30.days.ago)
                               .distinct
                               .pluck(:ip_address)

    if usual_ips.any? && !usual_ips.include?(activity_data[:ip_address])
      Rails.logger.info "[SECURITY] New IP address detected for admin #{admin_user.email}: #{activity_data[:ip_address]}"
    end
  end
end
