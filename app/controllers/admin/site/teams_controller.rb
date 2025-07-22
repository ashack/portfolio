# Site Admin Teams Controller
#
# PURPOSE:
# Provides site admin interface for viewing teams in a read-only capacity for customer support.
# Site admins can view team information but cannot create, edit, or manage teams.
#
# ACCESS RESTRICTIONS:
# - Site admins have READ-ONLY access to teams
# - NO create, edit, delete, or management capabilities
# - Cannot create teams (only super admins can)
# - Cannot manage team members or billing
# - Inherits from Admin::Site::BaseController which enforces site_admin role
#
# BUSINESS RULES:
# - Only super admins can create teams
# - Site admins provide support for team customers
# - Teams are multi-tenant organizations with their own billing
# - Team members are invitation-only (cannot be direct users)
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Teams are separate ecosystem from direct users and enterprise groups
# - Site admins need visibility for customer support purposes
# - No crossover capabilities between user types
class Admin::Site::TeamsController < Admin::Site::BaseController
  before_action :set_team, only: [ :show ]

  # Display paginated list of all teams for site admin support overview
  #
  # WHAT IT SHOWS:
  # - All teams in the system for support context
  # - Team admin and member counts for support understanding
  # - Recent teams first for current support relevance
  #
  # SECURITY:
  # - Uses Pundit policy_scope to ensure site admin sees appropriate teams
  # - Includes admin and users to prevent N+1 queries
  #
  # SUPPORT USE CASES:
  # - Overview of all customer teams
  # - Understanding team structure for support tickets
  # - Identifying team growth patterns
  #
  # PERFORMANCE:
  # - Includes associations to prevent N+1 queries
  # - Paginated for better page load performance
  def index
    @teams = policy_scope(Team).includes(:admin, :users).order(created_at: :desc)
    @pagy, @teams = pagy(@teams)
  end

  # Display detailed team information for site admin support purposes
  #
  # WHAT IT SHOWS:
  # - Team details and current status
  # - Team admin and member information
  # - Team settings and configuration (read-only)
  #
  # SECURITY:
  # - Uses Pundit authorization to verify site admin can view this team
  # - No modification capabilities exposed
  #
  # SUPPORT USE CASES:
  # - Help team customers with member questions
  # - Understand team structure for support tickets
  # - Verify team status when customers report issues
  #
  # READ-ONLY ACCESS:
  # - Site admins cannot modify teams
  # - Cannot manage team members
  # - Cannot access team billing information
  def show
    authorize @team
  end

  private

  # Find team by slug for consistent URL structure
  #
  # SECURITY: Uses find_by! to raise 404 if not found (prevents enumeration)
  # ROUTING: Teams use slugs in URLs for clean, professional routing
  def set_team
    @team = Team.find_by!(slug: params[:id])
  end
end
