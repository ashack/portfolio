class UserNotificationService
  # Main method to notify critical changes using Noticed gem
  def self.notify_critical_changes(user, changes, admin_user = nil)
    return if changes.empty?

    changes.each do |field, change_data|
      case field.to_s
      when "email"
        notify_email_change(user, change_data["from"], change_data["to"], admin_user)
      when "system_role"
        notify_role_change(user, change_data["from"], change_data["to"], admin_user)
      when "status"
        notify_status_change(user, change_data["from"], change_data["to"], admin_user)
      end
    end
  end

  # Email change notification - uses both EmailChangeSecurityNotifier and direct mailer
  def self.notify_email_change(user, old_email, new_email, admin_user = nil)
    begin
      # Security notification to old email (using notifier)
      EmailChangeSecurityNotifier.with(
        user: user,
        old_email: old_email,
        new_email: new_email,
        changed_at: Time.current
      ).deliver(user)

      # Keep existing mailer for now for backward compatibility
      UserMailer.email_changed(user, old_email).deliver_later if user.persisted?

      log_notification("email_changed", user, admin_user, { old_email: old_email, new_email: new_email })
    rescue => e
      Rails.logger.error "Failed to send email change notification: #{e.message}"
    end
  end

  # Role change notification using RoleChangeNotifier
  def self.notify_role_change(user, old_role, new_role, admin_user = nil)
    begin
      RoleChangeNotifier.with(
        user: user,
        old_role: old_role,
        new_role: new_role,
        changed_by: admin_user
      ).deliver(user)

      log_notification("role_changed", user, admin_user, { old_role: old_role, new_role: new_role })
    rescue => e
      Rails.logger.error "Failed to send role change notification: #{e.message}"
    end
  end

  # Status change notification using UserStatusNotifier
  def self.notify_status_change(user, old_status, new_status, admin_user = nil)
    begin
      UserStatusNotifier.with(
        user: user,
        old_status: old_status,
        new_status: new_status,
        changed_by: admin_user
      ).deliver(user)

      log_notification("status_changed", user, admin_user, { old_status: old_status, new_status: new_status })
    rescue => e
      Rails.logger.error "Failed to send status change notification: #{e.message}"
    end
  end

  # Password reset notification using AdminActionNotifier
  def self.notify_password_reset(user, admin_user = nil, temporary_password = nil)
    begin
      if admin_user && temporary_password
        AdminActionNotifier.with(
          user: user,
          admin: admin_user,
          action: "password_reset",
          details: {
            temporary_password: temporary_password,
            expires_at: 24.hours.from_now
          }
        ).deliver(user)
      end

      log_notification("password_reset_initiated", user, admin_user)
    rescue => e
      Rails.logger.error "Failed to send password reset notification: #{e.message}"
    end
  end

  # Account confirmed notification using AccountConfirmedNotifier
  def self.notify_account_confirmed(user, admin_user = nil)
    begin
      AccountConfirmedNotifier.with(
        user: user,
        confirmed_at: user.confirmed_at || Time.current
      ).deliver(user)

      log_notification("account_confirmed", user, admin_user)
    rescue => e
      Rails.logger.error "Failed to send account confirmation notification: #{e.message}"
    end
  end

  # Account unlocked notification using AccountUnlockedNotifier
  def self.notify_account_unlocked(user, admin_user = nil, reason = nil)
    begin
      AccountUnlockedNotifier.with(
        user: user,
        unlocked_by: admin_user,
        reason: reason
      ).deliver(user)

      log_notification("account_unlocked", user, admin_user)
    rescue => e
      Rails.logger.error "Failed to send account unlock notification: #{e.message}"
    end
  end

  private

  def self.log_notification(notification_type, user, admin_user, details = {})
    log_data = {
      notification_type: notification_type,
      user_id: user.id,
      user_email: user.email,
      admin_user_id: admin_user&.id,
      admin_user_email: admin_user&.email,
      details: details,
      timestamp: Time.current
    }

    Rails.logger.info "[USER NOTIFICATION] #{notification_type} sent to #{user.email} by #{admin_user&.email || 'system'}: #{details}"
  end
end
