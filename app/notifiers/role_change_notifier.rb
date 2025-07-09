# Notifier for system role changes
# Handles notifications when a user's system role is updated
class RoleChangeNotifier < ApplicationNotifier
  # Required params:
  # - user: The user whose role changed
  # - old_role: Previous system role
  # - new_role: New system role
  # - changed_by: Admin who made the change

  # Deliver by email
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :role_changed
    config.params = -> { params }
    config.if = -> { notification_enabled?("email", "role_changes") }
  end

  # In-app notifications are saved automatically by the Noticed gem

  # TODO: Phase 5 - Add ActionCable delivery for real-time notifications
  # deliver_by :action_cable do |config|
  #   config.channel = "NotificationsChannel"
  #   config.stream = -> { "user_#{recipient.id}_notifications" }
  #   config.message = -> { message }
  #   config.if = -> {
  #     notification_enabled?("real_time", "enabled") &&
  #     notification_enabled?("in_app", "role_changes")
  #   }
  # end

  # Notification content for display
  def message
    role_display = {
      "user" => "Standard User",
      "site_admin" => "Site Administrator",
      "super_admin" => "Super Administrator"
    }

    "Your system role has been changed to #{role_display[params[:new_role]] || params[:new_role]}"
  end

  # Additional details for the notification
  def details
    {
      old_role: params[:old_role],
      new_role: params[:new_role],
      changed_by: params[:changed_by]&.full_name,
      changed_at: formatted_timestamp,
      privileges_info: role_privileges_info
    }
  end

  # URL to redirect user when clicking notification
  def url
    case params[:new_role]
    when "super_admin"
      Rails.application.routes.url_helpers.admin_super_root_path
    when "site_admin"
      Rails.application.routes.url_helpers.admin_site_root_path
    else
      Rails.application.routes.url_helpers.root_path
    end
  end

  # Icon for the notification
  def icon
    case params[:new_role]
    when "super_admin"
      "crown"
    when "site_admin"
      "shield-check"
    else
      "user"
    end
  end

  # Notification type for filtering
  def notification_type
    "role_change"
  end

  private

  def role_privileges_info
    case params[:new_role]
    when "super_admin"
      "You now have full system access including team and enterprise creation"
    when "site_admin"
      "You now have customer support access with read-only billing"
    else
      "You have standard user access"
    end
  end
end
