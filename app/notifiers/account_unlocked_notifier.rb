# Notifier for account unlock events
# Sent when an account is unlocked by an admin
class AccountUnlockedNotifier < ApplicationNotifier
  # Required params:
  # - user: The user whose account was unlocked
  # - unlocked_by: Admin who unlocked the account
  # - reason: Optional reason for unlock

  # Deliver by email
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :account_unlocked
    config.params = -> { params }
    config.if = -> { notification_enabled?("email", "security_alerts") }
  end

  # In-app notifications are saved automatically by the Noticed gem

  # Notification content for display
  def message
    "Your account has been unlocked and you can now sign in"
  end

  # Additional details for the notification
  def details
    {
      unlocked_by: params[:unlocked_by]&.full_name || "System Administrator",
      unlocked_at: formatted_timestamp,
      reason: params[:reason] || "Account security review completed",
      security_tip: "If you didn't request this, please contact support immediately"
    }
  end

  # URL to redirect user when clicking notification
  def url
    Rails.application.routes.url_helpers.new_user_session_path
  end

  # Icon for the notification
  def icon
    "lock-open"
  end

  # Notification type for filtering
  def notification_type
    "security_alert"
  end

  # Priority level for this notification
  def priority
    "high"
  end
end
