class InvitationMailer < ApplicationMailer
  default from: "noreply@saasapp.com"

  def team_invitation(invitation)
    @invitation = invitation
    @team = invitation.team
    @invited_by = invitation.invited_by
    @accept_url = invitation_url(@invitation.token)

    mail(
      to: @invitation.email,
      subject: "You've been invited to join #{@team.name} on SaaS App"
    )
  end

  def invite
    @invitation = params[:invitation]
    @invited_by = @invitation.invited_by
    @accept_url = invitation_url(@invitation.token)

    if @invitation.enterprise_invitation?
      @organization = @invitation.invitable
      subject = "You've been invited to join #{@organization.name} on SaaS App"
    else
      @team = @invitation.invitable
      subject = "You've been invited to join #{@team.name} on SaaS App"
    end

    mail(
      to: @invitation.email,
      subject: subject
    )
  end
end
