class AuditLogService
  def self.log(admin_user:, target_user:, action:, details: {}, request: nil)
    AuditLog.create!(
      user: admin_user,
      target_user: target_user,
      action: action,
      details: details,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create audit log: #{e.message}"
    Rails.logger.error "Details: admin_user=#{admin_user&.id}, target_user=#{target_user&.id}, action=#{action}"
  end

  def self.log_user_update(admin_user:, target_user:, changes:, request: nil)
    return if changes.empty?

    log(
      admin_user: admin_user,
      target_user: target_user,
      action: "user_update",
      details: {
        changes: changes,
        timestamp: Time.current
      },
      request: request
    )
  end

  def self.log_status_change(admin_user:, target_user:, old_status:, new_status:, request: nil)
    log(
      admin_user: admin_user,
      target_user: target_user,
      action: "status_change",
      details: {
        old_status: old_status,
        new_status: new_status,
        timestamp: Time.current
      },
      request: request
    )
  end

  def self.log_role_change(admin_user:, target_user:, old_role:, new_role:, request: nil)
    log(
      admin_user: admin_user,
      target_user: target_user,
      action: "role_change",
      details: {
        old_role: old_role,
        new_role: new_role,
        timestamp: Time.current
      },
      request: request
    )
  end

  def self.log_user_change(admin_user:, target_user:, changes:, request: nil)
    log(
      admin_user: admin_user,
      target_user: target_user,
      action: "user_change",
      details: {
        changes: changes,
        timestamp: Time.current
      },
      request: request
    )
  end

  def self.log_password_reset(admin_user:, target_user:, request: nil)
    log(
      admin_user: admin_user,
      target_user: target_user,
      action: "password_reset",
      details: {
        timestamp: Time.current
      },
      request: request
    )
  end

  def self.log_email_confirm(admin_user:, target_user:, request: nil)
    log(
      admin_user: admin_user,
      target_user: target_user,
      action: "email_confirm",
      details: {
        timestamp: Time.current
      },
      request: request
    )
  end

  def self.log_account_unlock(admin_user:, target_user:, request: nil)
    log(
      admin_user: admin_user,
      target_user: target_user,
      action: "account_unlock",
      details: {
        timestamp: Time.current
      },
      request: request
    )
  end

  def self.log_impersonate(admin_user:, target_user:, request: nil)
    log(
      admin_user: admin_user,
      target_user: target_user,
      action: "impersonate",
      details: {
        timestamp: Time.current
      },
      request: request
    )
  end

  # Enhanced activity tracking methods
  def self.log_admin_login(admin_user:, request: nil)
    log(
      admin_user: admin_user,
      target_user: admin_user, # Self-referential for login tracking
      action: "admin_login",
      details: {
        timestamp: Time.current,
        session_id: request&.session&.id&.public_id
      },
      request: request
    )
  end

  def self.log_admin_logout(admin_user:, request: nil)
    log(
      admin_user: admin_user,
      target_user: admin_user,
      action: "admin_logout",
      details: {
        timestamp: Time.current,
        session_duration: calculate_session_duration(admin_user)
      },
      request: request
    )
  end

  def self.log_team_action(admin_user:, team:, action:, details: {}, request: nil)
    # Create a dummy user record for team actions (using team admin as target)
    target_user = team.admin || admin_user

    log(
      admin_user: admin_user,
      target_user: target_user,
      action: action,
      details: details.merge({
        team_id: team.id,
        team_name: team.name,
        timestamp: Time.current
      }),
      request: request
    )
  end

  def self.log_invitation_action(admin_user:, invitation:, action:, request: nil)
    # For invitations, target_user might not exist yet
    target_user = admin_user # Use admin as fallback for invitations

    log(
      admin_user: admin_user,
      target_user: target_user,
      action: action,
      details: {
        invitation_email: invitation.email,
        team_id: invitation.team_id,
        team_name: invitation.team.name,
        role: invitation.role,
        timestamp: Time.current
      },
      request: request
    )
  end

  def self.log_system_action(admin_user:, action:, details: {}, request: nil)
    log(
      admin_user: admin_user,
      target_user: admin_user, # Self-referential for system actions
      action: action,
      details: details.merge({
        timestamp: Time.current
      }),
      request: request
    )
  end

  def self.log_bulk_operation(admin_user:, operation:, affected_count:, details: {}, request: nil)
    log(
      admin_user: admin_user,
      target_user: admin_user,
      action: "bulk_operation",
      details: details.merge({
        operation: operation,
        affected_count: affected_count,
        timestamp: Time.current
      }),
      request: request
    )
  end

  def self.log_security_event(admin_user:, target_user:, event_type:, details: {}, request: nil)
    log(
      admin_user: admin_user,
      target_user: target_user,
      action: event_type,
      details: details.merge({
        security_event: true,
        timestamp: Time.current
      }),
      request: request
    )
  end

  private

  def self.calculate_session_duration(user)
    last_login = AuditLog.by_admin(user.id)
                         .where(action: "admin_login")
                         .order(created_at: :desc)
                         .first

    return nil unless last_login

    duration_seconds = Time.current - last_login.created_at
    {
      seconds: duration_seconds.to_i,
      formatted: ActionController::Base.helpers.distance_of_time_in_words(last_login.created_at, Time.current)
    }
  end
end
