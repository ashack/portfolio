# Notifier for enterprise group invitations
# Sends email-only notifications to invited enterprise users
class EnterpriseInvitationNotifier < ApplicationNotifier
  # Required params:
  # - invitation: The invitation object
  # - enterprise_group: The enterprise group being invited to
  # - invited_by: User who sent the invitation

  # Email-only delivery (recipients don't have accounts yet)
  deliver_by :email do |config|
    config.mailer = "EnterpriseGroupMailer"
    config.method = :invitation
    config.params = -> { email_params }
    # Always send - no preference check for non-users
  end

  # Notification content for email
  def message
    "You've been invited to join #{params[:enterprise_group].name} Enterprise"
  end

  # Email-specific parameters
  def email_params
    {
      invitation: params[:invitation],
      enterprise_group: params[:enterprise_group],
      invited_by: params[:invited_by],
      invitation_url: invitation_url,
      expires_at: params[:invitation].expires_at,
      is_admin: params[:invitation].role == "admin"
    }
  end

  # Invitation acceptance URL
  def invitation_url
    Rails.application.routes.url_helpers.invitation_url(
      params[:invitation].token,
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )
  end

  # Details for logging
  def details
    {
      enterprise_name: params[:enterprise_group].name,
      enterprise_slug: params[:enterprise_group].slug,
      invited_by: params[:invited_by]&.full_name,
      role: params[:invitation].role,
      expires_at: params[:invitation].expires_at.strftime("%B %d, %Y"),
      plan: params[:enterprise_group].plan&.name
    }
  end

  # Notification type for filtering/logging
  def notification_type
    "enterprise_invitation"
  end

  # Priority level (enterprise invitations are high priority)
  def priority
    "high"
  end
end
