# Teams::BaseController - Foundation controller for all team-related functionality
#
# PURPOSE:
# - Serves as the base controller for all team-scoped operations in the SaaS application
# - Provides core authentication and authorization for team access
# - Implements the team-based routing pattern using slug-based URLs (/teams/:team_slug/)
# - Enforces the triple-track user system boundaries for team access
#
# TRIPLE-TRACK USER SYSTEM INTEGRATION:
# - INVITED USERS: Team members created via invitation (primary users of team controllers)
# - DIRECT USERS: Can only access if they own a team (owns_team: true)
# - ENTERPRISE USERS: Cannot access team controllers (separate enterprise namespace)
#
# ACCESS CONTROL:
# - Only invited users and direct users who own teams can access team controllers
# - Team access is strictly scoped - users can only access their assigned team
# - Uses slug-based routing for clean URLs and team identification
# - Implements defense-in-depth security with both user type and team membership checks
#
# ROUTING STRUCTURE:
# - All team routes follow pattern: /teams/:team_slug/*
# - Team slug is extracted from URL and used to load the appropriate team
# - Team membership is verified on every request to prevent unauthorized access
#
# SECURITY CONSIDERATIONS:
# - Prevents cross-team access through strict team_id matching
# - Validates user type permissions before allowing team access
# - Uses slug-based lookups with ! to raise clear errors for invalid teams
# - Implements fail-secure defaults (redirect to root on unauthorized access)
#
class Teams::BaseController < ApplicationController
  before_action :require_team_member!
  before_action :set_team

  private

  # TEAM MEMBER AUTHENTICATION
  # Enforces the triple-track user system rules for team access:
  # - Invited users (invited? = true): Primary team members created via invitation
  # - Direct users who own teams (direct? = true && owns_team? = true): Can create and manage teams
  # - Blocks enterprise users and direct users who don't own teams
  #
  # This method ensures that only users who belong in the team ecosystem can access team controllers
  def require_team_member!
    unless current_user&.invited? || (current_user&.direct? && current_user&.owns_team?)
      flash[:alert] = "You must be a team member to access this area."
      redirect_to root_path
    end
  end

  # TEAM LOADING AND AUTHORIZATION
  # Loads the team from the URL slug and verifies user access:
  # - Uses find_by_slug! to raise ActiveRecord::RecordNotFound for invalid slugs
  # - Checks that current user's team_id matches the requested team
  # - Prevents users from accessing other teams even if they know the slug
  #
  # This implements strict team isolation - each user can only access their assigned team
  def set_team
    @team = Team.find_by_slug!(params[:team_slug])

    unless current_user.team_id == @team.id
      flash[:alert] = "You don't have access to this team."
      redirect_to root_path
    end
  end
end
