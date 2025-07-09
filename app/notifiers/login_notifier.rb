# Notifier for login events from new locations or devices
class LoginNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :login_notification
    config.params = -> { params }
    config.if = -> { notification_enabled?("email", "security_alerts") }
  end

  # In-app notifications are saved automatically by Noticed gem

  notification_methods do
    def message
      "New login from #{params[:location]} using #{browser_info}"
    end

    def icon
      "sign-in"
    end

    def notification_type
      "security_alert"
    end

    def url
      Rails.application.routes.url_helpers.users_settings_path(anchor: "security-settings")
    end

    private

    def browser_info
      agent = params[:user_agent]
      return "Unknown browser" unless agent

      case agent
      when /Chrome/
        "Chrome"
      when /Safari/
        "Safari"
      when /Firefox/
        "Firefox"
      when /Edge/
        "Edge"
      else
        "Web browser"
      end
    end
  end
end