# Notifier for email change security alerts
# Sends security notifications to the OLD email address when email is changed
class EmailChangeSecurityNotifier < ApplicationNotifier
  # Required params:
  # - user: The user whose email changed
  # - old_email: The previous email address
  # - new_email: The new email address
  # - changed_at: When the change occurred

  # Email-only delivery to OLD email address (security requirement)
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :email_changed_security_alert
    config.params = -> { email_params }
    config.to = -> { params[:old_email] }
    # Always send security alerts - no preference check
  end

  # Notification content for email
  def message
    "Security Alert: Your email address has been changed"
  end

  # Email-specific parameters
  def email_params
    {
      user: params[:user],
      old_email: params[:old_email],
      new_email: params[:new_email],
      changed_at: params[:changed_at] || Time.current,
      security_link: security_link,
      support_link: support_link
    }
  end

  # Link to secure account if this change was unauthorized
  def security_link
    Rails.application.routes.url_helpers.new_user_password_url(
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )
  end

  # Support contact link
  def support_link
    "mailto:support@#{Rails.application.config.action_mailer.default_url_options[:host]}"
  end

  # Details for logging
  def details
    {
      old_email: params[:old_email],
      new_email: params[:new_email],
      changed_at: params[:changed_at] || formatted_timestamp,
      ip_address: params[:ip_address],
      user_agent: params[:user_agent]
    }
  end

  # Notification type for filtering/logging
  def notification_type
    "security_alert"
  end

  # Priority level (security alerts are always high priority)
  def priority
    "critical"
  end

  # Security flag
  def security_notification?
    true
  end
end
