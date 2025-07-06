# Notifier for admin-initiated actions on user accounts
# Handles notifications for password resets, account modifications, etc.
class AdminActionNotifier < ApplicationNotifier
  # Required params:
  # - user: The user affected by the action
  # - admin: The admin who performed the action
  # - action: Type of action ('password_reset', 'account_update', etc.)
  # - details: Additional details about the action

  # Deliver by email
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :admin_action
    config.params = -> { email_params }
    config.if = -> { notification_enabled?("email", "admin_actions") }
  end

  # In-app notifications are saved automatically by the Noticed gem

  # TODO: Phase 5 - Add ActionCable delivery for real-time notifications
  # deliver_by :action_cable do |config|
  #   config.channel = "NotificationsChannel"
  #   config.stream = -> { "user_#{recipient.id}_notifications" }
  #   config.message = -> { message }
  #   config.if = -> {
  #     notification_enabled?("real_time", "enabled") &&
  #     params[:action] == "password_reset"
  #   }
  # end

  # Notification content for display
  def message
    case params[:action]
    when "password_reset"
      "An administrator has reset your password"
    when "two_factor_disabled"
      "Two-factor authentication has been disabled on your account"
    when "sessions_cleared"
      "All active sessions have been terminated by an administrator"
    when "profile_updated"
      "Your profile has been updated by an administrator"
    else
      "An administrator has performed an action on your account"
    end
  end

  # Additional details for the notification
  def details
    base_details = {
      admin: params[:admin]&.full_name || "System Administrator",
      performed_at: formatted_timestamp,
      action_type: params[:action]
    }

    # Add action-specific details
    case params[:action]
    when "password_reset"
      details_hash = params[:details].is_a?(Hash) ? params[:details] : {}
      base_details.merge(
        temporary_password: details_hash[:temporary_password],
        expires_at: details_hash[:expires_at],
        instruction: "Please sign in and change your password immediately"
      )
    when "two_factor_disabled"
      details_hash = params[:details].is_a?(Hash) ? params[:details] : {}
      base_details.merge(
        reason: details_hash[:reason] || "Security review",
        recommendation: "Re-enable two-factor authentication for better security"
      )
    else
      details_hash = params[:details].is_a?(Hash) ? params[:details] : {}
      base_details.merge(details_hash)
    end
  end

  # URL to redirect user when clicking notification
  def url
    case params[:action]
    when "password_reset"
      Rails.application.routes.url_helpers.new_user_session_path
    when "two_factor_disabled", "profile_updated"
      Rails.application.routes.url_helpers.users_profile_path(recipient)
    else
      Rails.application.routes.url_helpers.user_dashboard_path
    end
  end

  # Icon for the notification
  def icon
    case params[:action]
    when "password_reset"
      "key"
    when "two_factor_disabled"
      "shield-warning"
    when "sessions_cleared"
      "sign-out"
    when "profile_updated"
      "user-gear"
    else
      "user-check"
    end
  end

  # Notification type for filtering
  def notification_type
    "admin_action"
  end

  # Priority based on action type
  def priority
    case params[:action]
    when "password_reset", "two_factor_disabled"
      "high"
    else
      "medium"
    end
  end

  private

  def email_params
    {
      user: recipient,
      admin: params[:admin],
      action: params[:action],
      details: params[:details] || {}
    }
  end
end
