# Teams::Admin::BaseController - Foundation for team administrative functionality
#
# PURPOSE:
# - Serves as base controller for all team administrative operations
# - Provides additional authorization layer for team admin functions
# - Inherits team access control from Teams::BaseController
# - Enforces team admin privileges for sensitive operations
#
# INHERITANCE HIERARCHY:
# - Inherits from Teams::BaseController (team access control)
# - Adds team admin authorization on top of team member access
# - Provides foundation for all admin/* controllers in team namespace
#
# ACCESS LEVEL: Team Admin Only
# - Requires team_admin? = true for access
# - More restrictive than general team member access
# - Both invited users with admin role and team owners can be admins
#
# ROUTE STRUCTURE:
# - All admin routes follow pattern: /teams/:team_slug/admin/*
# - Team slug inherited from parent controller
# - Admin routes nested under team namespace for clear separation
#
# TRIPLE-TRACK USER INTEGRATION:
# - INVITED USERS: Can be team admins if assigned admin role during invitation
# - DIRECT USERS (team owners): Automatically have team admin privileges (owns_team: true)
# - ENTERPRISE USERS: Cannot access (separate enterprise admin namespace)
#
# TEAM ADMIN TYPES:
# 1. Team Owner (Direct User): owns_team: true, full administrative control
# 2. Invited Admin: invited user with team_role: "admin", delegated privileges
#
# AUTHORIZATION FLOW:
# 1. Teams::BaseController: Verifies team membership and access
# 2. Teams::Admin::BaseController: Verifies team admin privileges
# 3. Individual controllers: Implement specific admin function authorization
#
# SECURITY CONSIDERATIONS:
# - Double authorization: team access + admin privileges
# - Prevents privilege escalation from regular team members
# - Clear separation between member and admin functionality
# - Admin actions should be logged for audit purposes
# - Fail-secure redirect to team dashboard on unauthorized access
#
class Teams::Admin::BaseController < Teams::BaseController
  before_action :require_team_admin!

  private

  # TEAM ADMIN AUTHORIZATION
  # Verifies that current user has team administrative privileges
  # Works in conjunction with team membership verification from parent controller
  #
  # Team Admin Privileges:
  # - Team owners (direct users with owns_team: true) automatically qualify
  # - Invited users must have team_role: "admin" assigned during invitation
  # - Enterprise users cannot access team admin functions
  #
  # This creates a secure admin access pattern:
  # 1. User must be a team member (Teams::BaseController)
  # 2. User must have admin privileges (this method)
  # 3. Specific admin actions may have additional authorization
  def require_team_admin!
    unless current_user.team_admin?
      flash[:alert] = "You must be a team admin to access this area."
      redirect_to team_root_path(team_slug: @team.slug)
    end
  end
end
