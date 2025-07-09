class UpdateNotificationPreferencesDefault < ActiveRecord::Migration[8.0]
  def up
    # Update default value for notification_preferences
    change_column_default :users, :notification_preferences, from: nil, to: {
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

    # Update existing users with nil preferences
    User.where(notification_preferences: nil).update_all(
      notification_preferences: {
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
    )
  end

  def down
    change_column_default :users, :notification_preferences, from: nil, to: nil
  end
end
