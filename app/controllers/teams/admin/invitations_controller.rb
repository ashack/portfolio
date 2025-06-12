class Teams::Admin::InvitationsController < Teams::Admin::BaseController
  before_action :set_invitation, only: [ :show, :resend, :revoke ]

  def index
    @invitations = @team.invitations.includes(:invited_by).order(created_at: :desc)
    @pagy, @invitations = pagy(@invitations)
  end

  def show
    authorize @invitation
  end

  def new
    @invitation = @team.invitations.build
    authorize @invitation
  end

  def create
    @invitation = @team.invitations.build(invitation_params)
    @invitation.invited_by = current_user
    authorize @invitation

    if @invitation.save
      InvitationMailer.team_invitation(@invitation).deliver_later
      redirect_to teams_admin_invitations_path, notice: "Invitation was successfully sent."
    else
      render :new
    end
  end

  def resend
    authorize @invitation

    if @invitation.pending? && !@invitation.expired?
      InvitationMailer.team_invitation(@invitation).deliver_later
      redirect_to teams_admin_invitations_path, notice: "Invitation was resent."
    else
      redirect_to teams_admin_invitations_path, alert: "Cannot resend this invitation."
    end
  end

  def revoke
    authorize @invitation

    if @invitation.destroy
      redirect_to teams_admin_invitations_path, notice: "Invitation was revoked."
    else
      redirect_to teams_admin_invitations_path, alert: "Failed to revoke invitation."
    end
  end

  private

  def set_invitation
    @invitation = @team.invitations.find(params[:id])
  end

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end
end
