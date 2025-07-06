# Notifier for critical security alerts
# These notifications cannot be disabled by user preferences
class SecurityAlertNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = "SecurityMailer"
    config.method = :security_alert
    config.params = -> { params }
    # Security alerts always sent regardless of preferences
  end

  # In-app notifications are saved automatically by Noticed gem

  notification_methods do
    # Make this a critical notification
    def priority
      "critical"
    end

    def message
      case params[:alert_type]
      when "suspicious_login"
        "Suspicious login attempt detected from #{params[:location]}"
      when "password_reset_attempt"
        "Password reset requested from unknown location"
      when "failed_login_attempts"
        "Multiple failed login attempts from IP: #{params[:ip_address]}"
      else
        "Security alert: #{params[:alert_type]&.humanize}"
      end
    end

    def icon
      "shield-warning"
    end

    def notification_type
      "security_alert"
    end

    def url
      Rails.application.routes.url_helpers.users_settings_path(anchor: "security-settings")
    end

  end
end
