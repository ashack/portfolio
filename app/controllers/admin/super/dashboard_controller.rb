# Super Admin Dashboard Controller
#
# PURPOSE:
# Provides the main dashboard interface for super administrators with comprehensive
# platform statistics, user management overview, and system health monitoring.
#
# ACCESS RESTRICTIONS:
# - Only super admins can access this dashboard
# - Full access to all platform statistics including system users
# - Can see sensitive metrics and growth data
# - Inherits from Admin::Super::BaseController which enforces super_admin role
#
# BUSINESS INTELLIGENCE:
# - Platform-wide user statistics across all user types
# - Team and enterprise management overview
# - Recent activity monitoring for platform health
# - Growth metrics for strategic decision-making
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Shows statistics across direct, team, and enterprise ecosystems
# - Provides oversight of all user types and organizational structures
# - Supports strategic management of the entire platform
class Admin::Super::DashboardController < Admin::Super::BaseController
  # Dashboard shows statistics, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index

  # Main super admin dashboard with comprehensive platform overview
  #
  # PLATFORM STATISTICS:
  # - Total users (including all user types and system admins)
  # - Total teams and active team counts for organizational health
  # - User type distribution (direct vs team members)
  #
  # CUSTOMER-FACING STATISTICS:
  # - Active users excluding super admins (customer health metric)
  # - Inactive and locked users for support prioritization
  #
  # RECENT ACTIVITY MONITORING:
  # - Recent teams created (5 most recent with member context)
  # - Recent user registrations (10 most recent with organizational context)
  # - Recent user activities (10 most recent for platform engagement)
  #
  # PERFORMANCE OPTIMIZATIONS:
  # - Includes associations to prevent N+1 query problems
  # - Limited recent data queries for dashboard performance
  # - Separates system stats from customer-facing stats
  #
  # VIEW RENDERING:
  # - Uses modern dashboard template for enhanced UX
  def index
    # Super admin stats (all data)
    @total_users = User.count
    @total_teams = Team.count
    @active_teams = Team.active.count
    @direct_users = User.direct_users.count
    @team_users = User.team_members.count

    # Site admin stats (excluding super admins)
    @active_users = User.active.where.not(system_role: "super_admin").count
    @inactive_users = User.inactive.count
    @locked_users = User.locked.count

    # Recent data with optimized queries
    @recent_teams = Team.includes(:admin, :users).order(created_at: :desc).limit(5)
    @recent_users = User.includes(:team, :plan).where.not(system_role: "super_admin").order(created_at: :desc).limit(10)
    @recent_activities = User.includes(:team).where.not(system_role: "super_admin").order(last_activity_at: :desc).limit(10)

    render "index_modern"
  end
end
