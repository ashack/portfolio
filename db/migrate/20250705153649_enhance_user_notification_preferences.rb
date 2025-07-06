class EnhanceUserNotificationPreferences < ActiveRecord::Migration[8.0]
  def change
    # Add indexes for notification queries performance
    add_index :noticed_notifications, :read_at
    add_index :noticed_notifications, :seen_at
    add_index :noticed_notifications, [ :recipient_type, :recipient_id, :read_at ], name: "index_notifications_on_recipient_and_read_at"

    # Ensure notification_preferences has proper default structure
    # This is a no-op if the column already has the correct default
    change_column_default :users, :notification_preferences, from: {}, to: {
      email: {
        status_changes: true,
        role_changes: true,
        invitations: true,
        security_alerts: true,
        email_changes: true,
        admin_actions: true
      },
      in_app: {
        status_changes: true,
        role_changes: true,
        invitations: true,
        security_alerts: true,
        email_changes: true,
        admin_actions: true
      },
      real_time: {
        enabled: true,
        sound: false
      }
    }
  end
end
