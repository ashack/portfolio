class EnterpriseGroupMailer < ApplicationMailer
  def admin_invitation(invitation, enterprise_group)
    @invitation = invitation
    @enterprise_group = enterprise_group
    @invitation_url = invitation_url(@invitation)

    mail(
      to: @invitation.email,
      subject: "You've been invited to manage #{@enterprise_group.name}"
    )
  end
end
