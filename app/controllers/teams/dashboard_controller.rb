# Teams::DashboardController - Team member dashboard and overview
#
# PURPOSE:
# - Provides the main dashboard interface for team members
# - Displays team overview, member activity, and key metrics
# - Serves as the landing page for team members after login
# - Accessible to all team members (both regular members and admins)
#
# ACCESS LEVEL: Team Member
# - Available to both invited users and direct users who own teams
# - All team members can view the dashboard regardless of role
# - Does not require team admin privileges
#
# ROUTE STRUCTURE:
# - GET /teams/:team_slug/ (team_root_path)
# - Uses team slug for clean, team-specific URLs
# - Inherits team loading and authorization from Teams::BaseController
#
# TRIPLE-TRACK USER INTEGRATION:
# - INVITED USERS: Primary users - see their team dashboard after login
# - DIRECT USERS (team owners): Can view dashboard for teams they own
# - ENTERPRISE USERS: Cannot access (separate enterprise dashboard)
#
# DASHBOARD FEATURES:
# - Team member list with activity tracking (Ahoy analytics integration)
# - Recent member activities for engagement monitoring
# - Team overview and statistics
# - No sensitive administrative data (billing, invitations, etc.)
#
# SECURITY CONSIDERATIONS:
# - Skips Pundit verification as dashboard shows team's own aggregated data
# - No cross-team data leakage (team scope enforced by BaseController)
# - Activity data scoped to current team members only
# - Uses efficient database queries with includes to prevent N+1 queries
#
class Teams::DashboardController < Teams::BaseController
  # Dashboard shows team's own data, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  # TEAM DASHBOARD OVERVIEW
  # Displays key team information and member activity for all team members
  # Includes performance optimizations for member lists and activity tracking
  def index
    # Load team members with activity data (optimized with includes to prevent N+1)
    @team_members = @team.users.includes(:ahoy_visits).order(created_at: :desc)

    # Recent activity feed for team engagement monitoring
    # Only shows members who have been active (have last_activity_at set)
    @recent_activities = @team.users.where.not(last_activity_at: nil).order(last_activity_at: :desc).limit(10)
  end
end
