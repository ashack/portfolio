# Base notifier class that all other notifiers inherit from
# Provides shared configuration and helper methods for notifications
class ApplicationNotifier < Noticed::Event
  # Default delivery methods for all notifications
  # Individual notifiers can override or add to these

  # Access to the recipient (injected by NoticedNotificationExtensions)
  attr_accessor :recipient

  # Helper method to check if recipient has enabled a notification type
  def notification_enabled?(channel, type)
    return true unless recipient.respond_to?(:notification_preferences)

    preferences = recipient.notification_preferences || default_preferences
    preferences.dig(channel.to_s, type.to_s) != false
  end

  # Default notification preferences structure
  def default_preferences
    {
      "email" => {
        "status_changes" => true,
        "security_alerts" => true,
        "role_changes" => true,
        "team_members" => true,
        "invitations" => true,
        "admin_actions" => true,
        "account_updates" => true
      },
      "in_app" => {
        "status_changes" => true,
        "security_alerts" => true,
        "role_changes" => true,
        "team_members" => true,
        "invitations" => true,
        "admin_actions" => true,
        "account_updates" => true
      },
      "digest" => {
        "frequency" => "daily"
      },
      "marketing" => {
        "enabled" => true
      }
    }
  end

  # Common notification metadata
  def notification_metadata
    {
      created_at: Time.current,
      notification_id: SecureRandom.uuid
    }
  end

  # Format timestamp for display
  def formatted_timestamp
    Time.current.strftime("%B %d, %Y at %I:%M %p")
  end
end
