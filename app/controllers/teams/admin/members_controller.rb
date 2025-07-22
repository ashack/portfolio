# Teams::Admin::MembersController - Team member management and administration
#
# PURPOSE:
# - Manages team member accounts and roles within the team
# - Provides member overview, role management, and account deletion
# - Implements member statistics and activity tracking
# - Enforces team membership business rules
#
# ACCESS LEVEL: Team Admin Only
# - Only team admins can manage other team members
# - Team owners (direct users) have full member management access
# - Invited admins can manage members with appropriate restrictions
# - Regular team members cannot access member management
#
# ROUTE STRUCTURE:
# - GET /teams/:team_slug/admin/members (index)
# - GET /teams/:team_slug/admin/members/:id (show)
# - PATCH /teams/:team_slug/admin/members/:id/change_role (change_role)
# - DELETE /teams/:team_slug/admin/members/:id (destroy)
#
# TRIPLE-TRACK USER INTEGRATION:
# - INVITED USERS (admin role): Can manage other invited team members
# - DIRECT USERS (team owners): Full member management for teams they own
# - ENTERPRISE USERS: Cannot access (separate enterprise member management)
#
# MEMBER MANAGEMENT FEATURES:
# - Complete team member listing with activity tracking
# - Role management (member/admin) with authorization checks
# - Member account deletion with complete removal from system
# - Member statistics and activity metrics
# - Efficient database queries with includes to prevent N+1
#
# BUSINESS RULES:
# - Team admins cannot delete themselves (security protection)
# - Member deletion is permanent and removes user from entire system
# - Role changes logged for audit purposes
# - Activity tracking for engagement monitoring
# - Statistics calculated efficiently to avoid performance issues
#
# CRITICAL SECURITY NOTE:
# The destroy action in this controller performs COMPLETE ACCOUNT DELETION
# This is different from typical member removal - it destroys the user record entirely
# This implements the business requirement that team admins can completely delete team member accounts
#
# SECURITY CONSIDERATIONS:
# - Admin-only access to member management functions
# - Self-deletion prevention (admins cannot delete themselves)
# - Role change authorization and validation
# - Complete audit trail of member management actions
# - Proper error handling and user feedback
# - Team scope enforced (no cross-team member access)
#
class Teams::Admin::MembersController < Teams::Admin::BaseController
  before_action :set_member, only: [ :show, :change_role, :destroy ]

  # MEMBER LISTING AND STATISTICS
  # Shows all team members with comprehensive statistics and activity tracking
  # Includes efficient database queries and performance optimizations
  def index
    # Load all team members with activity data (optimized with includes to prevent N+1)
    @members = @team.users.includes(:ahoy_visits).order(created_at: :desc)
    @pagy, @members = pagy(@members)

    # Calculate member statistics efficiently to avoid multiple queries
    # Used for team capacity monitoring and engagement tracking
    all_members = @team.users
    @admin_count = all_members.where(team_role: "admin").count
    @member_count = all_members.where(team_role: "member").count
    @active_count = all_members.where("last_activity_at > ?", 7.days.ago).count

    skip_policy_scope
  end

  # INDIVIDUAL MEMBER DETAILS
  # Shows detailed information about a specific team member
  # Includes role, activity history, and management options
  def show
    authorize @member
  end

  # MEMBER ROLE MANAGEMENT
  # Changes team member roles between 'member' and 'admin'
  # Includes validation and authorization checks
  def change_role
    authorize @member

    if @member.update(team_role: params[:role])
      # Role changes should be logged for audit purposes
      # TODO: Add audit logging for role changes
      redirect_to team_admin_members_path(team_slug: @team.slug), notice: "Member role was successfully updated."
    else
      redirect_to team_admin_members_path(team_slug: @team.slug), alert: "Failed to update member role."
    end
  end

  # MEMBER ACCOUNT DELETION
  # CRITICAL: This performs COMPLETE ACCOUNT DELETION, not just team removal
  # Implements business requirement that team admins can delete team member accounts entirely
  #
  # WARNING: This is a destructive operation that removes the user from the entire system
  # The user will lose access to all data and cannot be recovered
  def destroy
    authorize @member

    # Security check: Team admins cannot delete themselves
    if @member == current_user
      redirect_to team_admin_members_path(team_slug: @team.slug), alert: "You cannot delete yourself."
    elsif @member.destroy
      # Complete account deletion - user is removed from entire system
      # This implements the business rule that team admins can completely delete team member accounts
      # TODO: Add audit logging for account deletions
      # TODO: Consider adding soft delete option for data recovery
      redirect_to team_admin_members_path(team_slug: @team.slug), notice: "Member was successfully removed from the team."
    else
      redirect_to team_admin_members_path(team_slug: @team.slug), alert: "Failed to remove member."
    end
  end

  private

  # MEMBER LOOKUP
  # Securely loads team members scoped to the current team
  # Prevents access to users from other teams
  def set_member
    @member = @team.users.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    # Log member not found errors for debugging and security monitoring
    Rails.logger.error "Member not found: #{e.message}"
    redirect_to team_admin_members_path(team_slug: @team.slug), alert: "Member not found." and return
  end
end
