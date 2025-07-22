# Super Admin Enterprise Group Invitations Controller
#
# PURPOSE:
# Manages invitation lifecycle for enterprise groups including resending and revoking invitations.
# Super admins can manage enterprise group invitations across all enterprise organizations.
#
# ACCESS RESTRICTIONS:
# - Only super admins can manage enterprise group invitations
# - Full control over invitation lifecycle (resend, revoke)
# - Can manage invitations for all enterprise groups platform-wide
# - Uses explicit super_admin check (not inheriting from BaseController)
#
# BUSINESS RULES:
# - Enterprise groups are invitation-only ecosystems
# - Invitations have 7-day expiry periods
# - Cannot revoke accepted invitations (user already onboarded)
# - Invitation management supports enterprise admin workflow
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Enterprise users are completely separate from direct and team users
# - Invitation system enforces enterprise ecosystem boundaries
# - No crossover between user types through invitations
#
# AUDIT & ACTIVITY:
# - Includes ActivityTrackable for admin action logging
# - All invitation actions tracked for enterprise security
class Admin::Super::EnterpriseGroupInvitationsController < ApplicationController
  include ActivityTrackable

  before_action :require_super_admin!
  before_action :set_enterprise_group
  before_action :set_invitation, only: [ :resend, :revoke ]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # Display paginated list of invitations for specific enterprise group
  #
  # INVITATION DATA:
  # - All invitations for the specified enterprise group
  # - Includes inviter information for context and audit
  # - Recent invitations first for management relevance
  #
  # SECURITY:
  # - Uses Pundit policy_scope for authorization consistency
  # - Scoped to specific enterprise group only
  #
  # MANAGEMENT USE CASES:
  # - Review pending enterprise group invitations
  # - Monitor invitation acceptance rates
  # - Manage invitation lifecycle (resend/revoke)
  def index
    @invitations = policy_scope(@enterprise_group.invitations).includes(:invited_by).order(created_at: :desc)
    @pagy, @invitations = pagy(@invitations)
  end

  # Resend enterprise group invitation with extended expiration
  #
  # RESEND REQUIREMENTS:
  # - Invitation must not be accepted yet
  # - Invitation must not be expired
  # - Extends expiration by 7 days from current time
  #
  # NOTIFICATION PROCESS:
  # - Uses EnterpriseInvitationNotifier for consistent messaging
  # - Includes enterprise group context and inviter information
  # - Delivers notification to invitation recipient
  #
  # BUSINESS LOGIC:
  # - Cannot resend accepted invitations (user already onboarded)
  # - Cannot resend expired invitations (need new invitation)
  # - Resets expiration timer for recipient convenience
  #
  # AUDIT TRAIL:
  # - Activity tracking logs resend actions
  # - Invitation update timestamp reflects resend activity
  def resend
    authorize @invitation

    if !@invitation.accepted? && !@invitation.expired?
      # Reset expiration to 7 days from now
      @invitation.update!(expires_at: 7.days.from_now)

      # Resend the invitation using notifier
      EnterpriseInvitationNotifier.with(
        invitation: @invitation,
        enterprise_group: @enterprise_group,
        invited_by: @invitation.invited_by
      ).deliver(@invitation)

      redirect_to admin_super_enterprise_group_path(@enterprise_group),
                  notice: "Invitation was resent to #{@invitation.email}."
    else
      redirect_to admin_super_enterprise_group_path(@enterprise_group),
                  alert: "Cannot resend this invitation."
    end
  end

  # Revoke enterprise group invitation (delete permanently)
  #
  # REVOCATION RULES:
  # - Cannot revoke accepted invitations (user already onboarded)
  # - Can revoke pending or expired invitations
  # - Permanent deletion (no undo)
  #
  # BUSINESS LOGIC:
  # - Accepted invitations represent completed user onboarding
  # - Revoking pending invitations prevents recipient from joining
  # - Used when invitation sent to wrong email or circumstances change
  #
  # SECURITY CONSIDERATIONS:
  # - Prevents unauthorized access if invitation sent incorrectly
  # - Cleans up unused invitations from enterprise group
  #
  # AUDIT TRAIL:
  # - Activity tracking logs revocation actions
  # - Invitation deletion logged for enterprise security
  def revoke
    authorize @invitation

    if @invitation.accepted?
      redirect_to admin_super_enterprise_group_path(@enterprise_group),
                  alert: "Cannot revoke an accepted invitation."
    elsif @invitation.destroy
      redirect_to admin_super_enterprise_group_path(@enterprise_group),
                  notice: "Invitation was revoked."
    else
      redirect_to admin_super_enterprise_group_path(@enterprise_group),
                  alert: "Failed to revoke invitation."
    end
  end

  private

  # Explicit super admin authorization check
  #
  # SECURITY:
  # - Explicitly checks for super_admin role
  # - Prevents access by site admins or regular users
  # - Redirects with clear error message
  #
  # NOTE:
  # - Uses explicit check instead of inheriting from BaseController
  # - Ensures only super admins can manage enterprise invitations
  def require_super_admin!
    unless current_user&.super_admin?
      flash[:alert] = "You must be a super admin to access this area."
      redirect_to root_path
    end
  end

  # Find enterprise group by slug from nested route
  #
  # ROUTING:
  # - Uses slug from enterprise_group_id parameter (nested route)
  # - find_by! raises 404 if enterprise group doesn't exist
  # - Supports clean URL structure for enterprise groups
  def set_enterprise_group
    @enterprise_group = EnterpriseGroup.find_by!(slug: params[:enterprise_group_id])
  end

  # Find invitation within enterprise group scope
  #
  # SECURITY:
  # - Scoped to specific enterprise group to prevent cross-group access
  # - Uses find() to raise 404 if invitation doesn't exist in group
  # - Ensures invitation belongs to the specified enterprise group
  def set_invitation
    @invitation = @enterprise_group.invitations.find(params[:id])
  end
end
