# Notifier for successful email confirmation
# Sent when a user successfully confirms their email address
class AccountConfirmedNotifier < ApplicationNotifier
  # Required params:
  # - user: The user who confirmed their email
  # - confirmed_at: Timestamp of confirmation

  # Deliver by email
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :account_confirmed
    config.params = -> { params }
    config.if = -> { notification_enabled?("email", "status_changes") }
  end

  # In-app notifications are saved automatically by the Noticed gem

  # Notification content for display
  def message
    "Your email address has been successfully confirmed"
  end

  # Additional details for the notification
  def details
    {
      email: recipient.email,
      confirmed_at: params[:confirmed_at] || formatted_timestamp,
      next_steps: next_steps_message
    }
  end

  # URL to redirect user when clicking notification
  def url
    if recipient.direct? && recipient.plan.present?
      Rails.application.routes.url_helpers.users_billing_index_path
    elsif recipient.team.present?
      Rails.application.routes.url_helpers.team_root_path(team_slug: recipient.team.slug)
    elsif recipient.enterprise_group.present?
      Rails.application.routes.url_helpers.enterprise_dashboard_path(enterprise_group_slug: recipient.enterprise_group.slug)
    else
      Rails.application.routes.url_helpers.user_dashboard_path
    end
  end

  # Icon for the notification
  def icon
    "envelope-check"
  end

  # Notification type for filtering
  def notification_type
    "account_update"
  end

  private

  def next_steps_message
    if recipient.direct?
      "You can now access all features and set up your subscription"
    elsif recipient.team.present?
      "You can now access your team workspace"
    elsif recipient.enterprise_group.present?
      "You can now access your enterprise workspace"
    else
      "You can now access all available features"
    end
  end
end
