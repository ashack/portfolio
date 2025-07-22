# Teams::Admin::InvitationsController - Team invitation management
#
# PURPOSE:
# - Manages team member invitations and invitation lifecycle
# - Allows team admins to invite new users to join the team
# - Handles invitation tracking, resending, and revocation
# - Enforces business rules around team invitations
#
# ACCESS LEVEL: Team Admin Only
# - Only team admins can send, manage, and revoke invitations
# - Team owners (direct users) have full invitation management access
# - Invited admins can invite new members with appropriate role restrictions
# - Regular team members cannot access invitation functionality
#
# ROUTE STRUCTURE:
# - GET /teams/:team_slug/admin/invitations (index)
# - GET /teams/:team_slug/admin/invitations/:id (show)
# - GET /teams/:team_slug/admin/invitations/new (new)
# - POST /teams/:team_slug/admin/invitations (create)
# - POST /teams/:team_slug/admin/invitations/:id/resend (resend)
# - DELETE /teams/:team_slug/admin/invitations/:id (revoke)
#
# TRIPLE-TRACK USER INTEGRATION:
# - INVITED USERS (admin role): Can invite new team members with role restrictions
# - DIRECT USERS (team owners): Full invitation management including admin role assignment
# - ENTERPRISE USERS: Cannot access (separate enterprise invitation system)
#
# BUSINESS RULES:
# - Only new email addresses can be invited (emails not in users table)
# - Invitations have 7-day expiration period
# - Accepted invitations cannot be revoked (user already joined)
# - Only team admins can assign admin roles to invitations
# - Regular admins can only invite members, not other admins
#
# INVITATION FEATURES:
# - Email-based invitation system with unique tokens
# - Role assignment (member/admin) with security checks
# - Invitation tracking and status management
# - Resend functionality for pending invitations
# - Revocation of pending invitations
# - Audit trail of invitation activities
#
# NOTIFICATION INTEGRATION:
# - TeamInvitationNotifier sends invitation emails
# - Automatic email notifications for invitation events
# - Includes team context and inviter information
# - Professional email templates with branding
#
# SECURITY CONSIDERATIONS:
# - Admin-only access to invitation management
# - Role assignment security (only admins can invite admins)
# - Email validation prevents duplicate invitations
# - Token-based invitation system prevents unauthorized access
# - Team scope enforced (no cross-team invitation access)
# - Invitation lifecycle properly managed
#
class Teams::Admin::InvitationsController < Teams::Admin::BaseController
  before_action :set_invitation, only: [ :show, :resend, :revoke ]

  # INVITATION LIST
  # Shows all team invitations with status tracking and management options
  # Includes sent, pending, accepted, and expired invitations
  def index
    # Load all invitations for the team with invited_by information
    # Ordered by creation date to show most recent invitations first
    @invitations = @team.invitations.includes(:invited_by).order(created_at: :desc)
    @pagy, @invitations = pagy(@invitations)
    skip_policy_scope
  end

  # INVITATION DETAILS
  # Shows detailed information about a specific invitation
  # Includes invitation status, role, and management options
  def show
    authorize @invitation
  end

  # NEW INVITATION FORM
  # Displays form for creating new team invitations
  # Includes email input and role selection with appropriate restrictions
  def new
    @invitation = @team.invitations.build
    authorize @invitation
  end

  # CREATE INVITATION
  # Processes new invitation requests with validation and notification
  # Enforces business rules and sends invitation emails
  def create
    @invitation = @team.invitations.build(invitation_params)
    @invitation.invited_by = current_user
    authorize @invitation

    if @invitation.save
      # Send invitation email notification using Noticed gem
      # Includes team context and inviter information for personalization
      TeamInvitationNotifier.with(
        invitation: @invitation,
        team: @team,
        invited_by: current_user
      ).deliver(@invitation)
      redirect_to team_admin_invitations_path(team_slug: @team.slug), notice: "Invitation was successfully sent."
    else
      render :new
    end
  end

  # RESEND INVITATION
  # Resends pending invitations that haven't been accepted or expired
  # Useful for following up on pending invitations
  def resend
    authorize @invitation

    # Can only resend invitations that are pending and not expired
    if !@invitation.accepted? && !@invitation.expired?
      TeamInvitationNotifier.with(
        invitation: @invitation,
        team: @team,
        invited_by: @invitation.invited_by
      ).deliver(@invitation)
      redirect_to team_admin_invitations_path(team_slug: @team.slug), notice: "Invitation was resent."
    else
      redirect_to team_admin_invitations_path(team_slug: @team.slug), alert: "Cannot resend this invitation."
    end
  end

  # REVOKE INVITATION
  # Cancels pending invitations before they are accepted
  # Cannot revoke invitations that have already been accepted
  def revoke
    authorize @invitation

    # Business rule: Cannot revoke accepted invitations (user already joined team)
    if @invitation.accepted?
      redirect_to team_admin_invitations_path(team_slug: @team.slug), alert: "Cannot revoke an accepted invitation. The user has already joined the team."
    elsif @invitation.destroy
      redirect_to team_admin_invitations_path(team_slug: @team.slug), notice: "Invitation was revoked."
    else
      redirect_to team_admin_invitations_path(team_slug: @team.slug), alert: "Failed to revoke invitation."
    end
  end

  private

  # INVITATION LOOKUP
  # Securely loads invitations scoped to the current team
  # Prevents access to invitations from other teams
  def set_invitation
    @invitation = @team.invitations.find(params[:id])
  end

  # INVITATION PARAMETERS
  # Filters and validates invitation parameters with security checks
  # Includes role assignment with proper authorization validation
  def invitation_params
    base_params = params.require(:invitation).permit(:email)

    # Safely handle role parameter with proper authorization checks
    # Prevents privilege escalation through role assignment
    allowed_role = determine_allowed_role(params[:invitation][:role])
    base_params.merge(role: allowed_role)
  end

  # ROLE AUTHORIZATION
  # Determines allowed invitation role based on current user privileges
  # Implements security checks to prevent privilege escalation
  def determine_allowed_role(requested_role)
    # Default to member role for security
    return "member" if requested_role.blank?

    # Only allow valid enum values defined in Invitation model
    return "member" unless Invitation.roles.keys.include?(requested_role)

    # Security: Only team admins can assign admin roles to prevent privilege escalation
    # Regular members cannot invite admins even if they somehow access this controller
    return "member" if requested_role == "admin" && !current_user.team_admin?

    requested_role
  end
end
