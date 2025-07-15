# Notifier for system-wide announcements
# Used for maintenance windows, new features, etc.
class SystemAnnouncementNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = "SystemMailer"
    config.method = :announcement
    config.params = -> { params }
    config.if = -> { notification_enabled?("email", "system_announcements") }
  end

  # In-app notifications are saved automatically by Noticed gem

  notification_methods do
    def priority
      params[:priority] || "medium"
    end

    def message
      params[:message]
    end

    def title
      params[:title]
    end

    def icon
      case params[:announcement_type]
      when "maintenance"
        "wrench"
      when "feature"
        "sparkle"
      when "security"
        "shield-check"
      else
        "megaphone"
      end
    end

    def notification_type
      "system_announcement"
    end

    def url
      # System announcements typically don't have a specific URL
      nil
    end
  end
end
