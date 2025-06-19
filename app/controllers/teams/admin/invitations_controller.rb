class Teams::Admin::InvitationsController < Teams::Admin::BaseController
  before_action :set_invitation, only: [ :show, :resend, :revoke ]

  def index
    @invitations = @team.invitations.includes(:invited_by).order(created_at: :desc)
    @pagy, @invitations = pagy(@invitations)
    skip_policy_scope
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
      redirect_to team_admin_invitations_path(team_slug: @team.slug), notice: "Invitation was successfully sent."
    else
      render :new
    end
  end

  def resend
    authorize @invitation

    if !@invitation.accepted? && !@invitation.expired?
      InvitationMailer.team_invitation(@invitation).deliver_later
      redirect_to team_admin_invitations_path(team_slug: @team.slug), notice: "Invitation was resent."
    else
      redirect_to team_admin_invitations_path(team_slug: @team.slug), alert: "Cannot resend this invitation."
    end
  end

  def revoke
    authorize @invitation

    if @invitation.accepted?
      redirect_to team_admin_invitations_path(team_slug: @team.slug), alert: "Cannot revoke an accepted invitation. The user has already joined the team."
    elsif @invitation.destroy
      redirect_to team_admin_invitations_path(team_slug: @team.slug), notice: "Invitation was revoked."
    else
      redirect_to team_admin_invitations_path(team_slug: @team.slug), alert: "Failed to revoke invitation."
    end
  end

  private

  def set_invitation
    @invitation = @team.invitations.find(params[:id])
  end

  def invitation_params
    base_params = params.require(:invitation).permit(:email)

    # Safely handle role parameter with proper authorization checks
    allowed_role = determine_allowed_role(params[:invitation][:role])
    base_params.merge(role: allowed_role)
  end

  def determine_allowed_role(requested_role)
    # Default to member role
    return "member" if requested_role.blank?

    # Only allow valid enum values
    return "member" unless Invitation.roles.keys.include?(requested_role)

    # Security: Only team admins can assign admin roles
    return "member" if requested_role == "admin" && !current_user.team_admin?

    requested_role
  end
end
