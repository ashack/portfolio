class UserNotificationService
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

  def self.notify_email_change(user, old_email, new_email, admin_user = nil)
    begin
      UserMailer.email_changed(user, old_email).deliver_later
      log_notification("email_changed", user, admin_user, { old_email: old_email, new_email: new_email })
    rescue => e
      Rails.logger.error "Failed to send email change notification: #{e.message}"
    end
  end

  def self.notify_role_change(user, old_role, new_role, admin_user = nil)
    begin
      UserMailer.role_changed(user, old_role, new_role).deliver_later
      log_notification("role_changed", user, admin_user, { old_role: old_role, new_role: new_role })
    rescue => e
      Rails.logger.error "Failed to send role change notification: #{e.message}"
    end
  end

  def self.notify_status_change(user, old_status, new_status, admin_user = nil)
    begin
      UserMailer.status_changed(user, old_status, new_status).deliver_later
      log_notification("status_changed", user, admin_user, { old_status: old_status, new_status: new_status })
    rescue => e
      Rails.logger.error "Failed to send status change notification: #{e.message}"
    end
  end

  def self.notify_password_reset(user, admin_user = nil)
    begin
      # Password reset notifications are handled by the PasswordResetService
      log_notification("password_reset_initiated", user, admin_user)
    rescue => e
      Rails.logger.error "Failed to log password reset notification: #{e.message}"
    end
  end

  def self.notify_account_confirmed(user, admin_user = nil)
    begin
      UserMailer.account_confirmed(user).deliver_later
      log_notification("account_confirmed", user, admin_user)
    rescue => e
      Rails.logger.error "Failed to send account confirmation notification: #{e.message}"
    end
  end

  def self.notify_account_unlocked(user, admin_user = nil)
    begin
      UserMailer.account_unlocked(user).deliver_later
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
