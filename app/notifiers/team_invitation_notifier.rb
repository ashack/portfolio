# Notifier for team invitations
# Sends email-only notifications to invited users (they don't have accounts yet)
class TeamInvitationNotifier < ApplicationNotifier
  # Required params:
  # - invitation: The invitation object
  # - team: The team being invited to
  # - invited_by: User who sent the invitation

  # Email-only delivery (recipients don't have accounts yet)
  deliver_by :email do |config|
    config.mailer = "InvitationMailer"
    config.method = :team_invitation
    config.params = -> { email_params }
    # Always send - no preference check for non-users
  end

  # Notification content for email
  def message
    "You've been invited to join #{params[:team].name}"
  end

  # Email-specific parameters
  def email_params
    {
      invitation: params[:invitation],
      team: params[:team],
      invited_by: params[:invited_by],
      invitation_url: invitation_url,
      expires_at: params[:invitation].expires_at
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
      team_name: params[:team].name,
      team_slug: params[:team].slug,
      invited_by: params[:invited_by]&.full_name,
      role: params[:invitation].role,
      expires_at: params[:invitation].expires_at.strftime("%B %d, %Y")
    }
  end

  # Notification type for filtering/logging
  def notification_type
    "team_invitation"
  end
end
