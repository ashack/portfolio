# Notifier for account updates
class AccountUpdateNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :account_update_notification
    config.params = -> { params }
    config.if = -> { notification_enabled?("email", "account_updates") }
  end

  notification_methods do
    def message
      changes_text = params[:changes].map do |field, (old_val, new_val)|
        "#{field.to_s.humanize}: #{old_val} → #{new_val}"
      end.join(", ")

      "Your account was updated: #{changes_text}"
    end

    def icon
      "user-circle"
    end

    def notification_type
      "account_update"
    end

    def url
      Rails.application.routes.url_helpers.users_profile_path(recipient)
    end
  end
end
