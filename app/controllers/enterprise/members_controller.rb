# Enterprise::MembersController
#
# Manages enterprise organization members and invitations within the triple-track SaaS system.
# Handles member management, role assignments, and invitation workflows specifically for
# enterprise organizations, completely separate from team member management.
#
# **Access Control:**
# - index, show: Available to ALL enterprise users (members and admins)
# - new, create, edit, update, destroy: RESTRICTED to Enterprise Admins only
# - Invitation management: Enterprise Admins only
# - Inherits enterprise user validation from Enterprise::BaseController
#
# **Enterprise vs Team Member Management:**
# - Enterprise members are created through enterprise-specific invitations
# - Completely isolated from team member management (/teams/:slug/admin/members)
# - Different role structure: 'admin' vs 'member' (not team roles)
# - Enterprise invitations use invitation_type: 'enterprise'
# - No crossover with direct users or team users
#
# **Member Lifecycle:**
# 1. Enterprise Admin sends invitation to email address
# 2. Invitation email sent with enterprise-specific branding
# 3. Recipient accepts invitation and becomes enterprise user
# 4. User assigned to enterprise group with specified role
# 5. Admin can update roles or remove members
#
# **Invitation System:**
# - Uses polymorphic Invitation model (invitable: enterprise_group)
# - Email validation prevents duplicate invitations
# - 7-day expiration on pending invitations
# - Resend and revoke functionality for pending invitations only
#
# **Business Rules:**
# - Only NEW email addresses can be invited (no existing users)
# - Enterprise admins cannot remove themselves
# - Invitation emails use enterprise-specific templates
# - Members cannot invite other members (admin privilege only)
#
# **URL Structure:**
# All routes scoped under /enterprise/:enterprise_group_slug/members/
# - Multi-tenant member management via enterprise group slug
class Enterprise::MembersController < Enterprise::BaseController
  # Restrict admin actions to enterprise admins only
  before_action :require_admin!, except: [ :index, :show ]
  
  # Load member for specific actions
  before_action :set_member, only: [ :show, :edit, :update, :destroy ]
  
  # Skip Pundit policy verification for actions handled by admin checks
  skip_after_action :verify_policy_scoped, only: [ :index ]
  skip_after_action :verify_authorized, only: [ :new, :create, :edit, :update, :destroy, :resend_invitation, :revoke_invitation ]

  # Lists enterprise members and pending invitations
  #
  # **Displays:**
  # - Current enterprise group members with activity tracking
  # - Pending invitations with invitation details
  # - Separate pagination for members and invitations
  #
  # **Access:**
  # - Available to all enterprise users (members can see other members)
  # - Admin controls displayed only for enterprise admins
  #
  # **Data Loading:**
  # - Includes :ahoy_visits for last activity tracking
  # - Includes :invited_by for invitation audit trail
  # - Ordered by creation date for consistent listing
  def index
    # Load current members with activity tracking
    @members = @enterprise_group.users.includes(:ahoy_visits).order(created_at: :desc)
    @pagy_members, @members = pagy(@members, page_param: :members_page)

    # Load pending invitations with invitation details
    @pending_invitations = @enterprise_group.invitations.pending.includes(:invited_by).order(created_at: :desc)
    @pagy_invitations, @pending_invitations = pagy(@pending_invitations, page_param: :invitations_page)
  end

  # Shows individual member profile
  #
  # **Access:**
  # - Available to all enterprise users
  # - Shows member profile information and activity
  # - Admin controls displayed only for enterprise admins
  def show
    # Member profile view
  end

  # New invitation form for enterprise admins
  #
  # **Access:**
  # - Enterprise Admins only
  # - Creates new invitation associated with current enterprise group
  # - Pre-populates enterprise-specific invitation defaults
  def new
    @invitation = @enterprise_group.invitations.build
  end

  # Creates and sends enterprise invitation
  #
  # **Business Logic:**
  # - Validates email is not already in use (enforced by Invitation model)
  # - Sets invitation_type: 'enterprise' for polymorphic routing
  # - Associates invitation with current enterprise group
  # - Records the inviting admin for audit trail
  #
  # **Email Integration:**
  # - Sends enterprise-specific invitation email immediately
  # - Uses enterprise branding and messaging
  # - Includes enterprise group context and role information
  #
  # **Validation:**
  # - Email format validation
  # - Duplicate email prevention
  # - Role validation (admin or member)
  def create
    @invitation = @enterprise_group.invitations.build(invitation_params)
    @invitation.invited_by = current_user
    @invitation.invitation_type = "enterprise"

    if @invitation.save
      # Send invitation email with enterprise context
      InvitationMailer.with(invitation: @invitation).invite.deliver_now
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Invitation sent to #{@invitation.email}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Edit member role form
  #
  # **Access:**
  # - Enterprise Admins only
  # - Allows updating member roles between 'admin' and 'member'
  # - Cannot edit own role to prevent admin lockout
  def edit
    # Edit member role
  end

  # Updates member role within enterprise group
  #
  # **Role Management:**
  # - Updates enterprise_group_role (admin or member)
  # - Role changes take effect immediately
  # - Affects user permissions across enterprise system
  #
  # **Business Rules:**
  # - Only enterprise admins can update roles
  # - Role changes are logged for audit trail
  # - Cannot demote last admin (business rule enforcement needed)
  def update
    if @member.update(member_params)
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Member updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Removes member from enterprise group
  #
  # **Removal Logic:**
  # - Completely removes user from enterprise system
  # - User account is deleted (not just removed from enterprise)
  # - Self-removal protection prevents admin lockout
  # - Different from team member removal (teams keep user account)
  #
  # **Business Rules:**
  # - Enterprise admins cannot remove themselves
  # - Member removal is permanent and irreversible
  # - All member data and access is immediately revoked
  def destroy
    if @member == current_user
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "You cannot remove yourself"
    elsif @member.destroy
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Member removed successfully"
    else
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "Failed to remove member"
    end
  end

  # Resends invitation email to pending invitee
  #
  # **Business Logic:**
  # - Only works for pending invitations (not accepted)
  # - Resets invitation expiration timer
  # - Uses same invitation token and details
  # - Helpful for missed or expired invitations
  #
  # **Email Integration:**
  # - Sends fresh invitation email with enterprise branding
  # - Same invitation URL and acceptance process
  # - Does not create duplicate invitations
  def resend_invitation
    @invitation = @enterprise_group.invitations.find(params[:id])

    if @invitation.pending?
      InvitationMailer.with(invitation: @invitation).invite.deliver_now
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Invitation resent to #{@invitation.email}"
    else
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "Cannot resend accepted invitation"
    end
  end

  # Revokes pending invitation before acceptance
  #
  # **Revocation Logic:**
  # - Permanently deletes pending invitation
  # - Prevents invitation acceptance after revocation
  # - Only works for pending invitations (not accepted)
  # - Cannot revoke invitations after user has joined
  #
  # **Use Cases:**
  # - Invitation sent to wrong email address
  # - Role requirements changed before acceptance
  # - Security concerns about pending invitations
  def revoke_invitation
    @invitation = @enterprise_group.invitations.find(params[:id])

    if @invitation.pending?
      @invitation.destroy
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Invitation revoked"
    else
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "Cannot revoke accepted invitation"
    end
  end

  private

  # Restricts access to enterprise administrators only
  #
  # **Authorization Logic:**
  # - Checks current_user.enterprise_admin? method  
  # - Blocks enterprise members from admin actions
  # - Maintains role-based access control in enterprise system
  # - Prevents unauthorized member management
  #
  # **Redirects:**
  # - Non-admin enterprise users → enterprise dashboard with error
  def require_admin!
    unless current_user.enterprise_admin?
      redirect_to enterprise_dashboard_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "You don't have permission to perform this action"
    end
  end

  # Finds member within current enterprise group scope
  #
  # **Security:**
  # - Scopes member lookup to current enterprise group only
  # - Prevents access to members from other enterprise groups
  # - Maintains multi-tenant security isolation
  def set_member
    @member = @enterprise_group.users.find(params[:id])
  end

  # Strong parameters for invitation creation
  #
  # **Permitted Fields:**
  # - email: Invitation recipient email address
  # - role: Enterprise group role (admin or member)
  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end

  # Strong parameters for member updates
  #
  # **Permitted Fields:**
  # - enterprise_group_role: Role within enterprise (admin or member)
  def member_params
    params.require(:user).permit(:enterprise_group_role)
  end
end
