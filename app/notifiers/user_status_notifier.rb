# Notifier for user account status changes
# Handles notifications when user status changes to active, inactive, or locked
class UserStatusNotifier < ApplicationNotifier
  # Required params:
  # - user: The user whose status changed
  # - old_status: Previous status
  # - new_status: New status
  # - changed_by: Admin who made the change

  # Deliver by email
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :status_changed
    config.params = -> { params }
    config.if = -> { notification_enabled?("email", "status_changes") }
  end

  # In-app notifications are saved automatically by Noticed gem

  # Notification content for in-app display
  def message
    case params[:new_status]
    when "active"
      "Your account has been reactivated"
    when "inactive"
      "Your account has been deactivated"
    when "locked"
      "Your account has been locked for security reasons"
    else
      "Your account status has been updated"
    end
  end

  # Additional details for the notification
  def details
    {
      old_status: params[:old_status],
      new_status: params[:new_status],
      changed_by: params[:changed_by]&.full_name,
      changed_at: formatted_timestamp
    }
  end

  # URL to redirect user when clicking notification
  def url
    Rails.application.routes.url_helpers.users_profile_path(recipient)
  end

  # Icon for the notification (using Phosphor icons)
  def icon
    case params[:new_status]
    when "active"
      "check-circle"
    when "inactive"
      "warning-circle"
    when "locked"
      "lock"
    else
      "info"
    end
  end

  # Notification type for filtering
  def notification_type
    "status_change"
  end
end
