# Site Admin Dashboard Controller
#
# PURPOSE:
# Provides the main dashboard interface for site administrators with user statistics and monitoring.
# Site admins are customer support focused with read-only access to user and system data.
#
# ACCESS RESTRICTIONS:
# - Site admins cannot create teams or enterprise groups
# - Read-only access to user statistics (no billing access)
# - Cannot modify system settings or perform destructive actions
# - Inherits from Admin::Site::BaseController which enforces site_admin role
#
# BUSINESS RULES:
# - Excludes super_admin users from statistics to show customer-facing data
# - Focuses on user support metrics (active/inactive/locked counts)
# - No financial or sensitive system data exposed
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Shows statistics across all user types (direct, team, enterprise)
# - Provides support context for the different user ecosystems
# - No team creation or enterprise management capabilities
class Admin::Site::DashboardController < Admin::Site::BaseController
  # Dashboard shows statistics, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index

  # Main dashboard view displaying user statistics and recent activity for site admin support
  #
  # STATISTICS CALCULATED:
  # - Total users (excluding super admins for customer-focused view)
  # - Active users for support workload assessment
  # - Inactive/locked users for support prioritization
  # - Recent user registrations for monitoring growth
  # - Recent activity for identifying support needs
  #
  # SECURITY CONSIDERATIONS:
  # - Excludes super_admin users from all statistics
  # - No financial or sensitive system information exposed
  # - Read-only data access only
  #
  # PERFORMANCE NOTES:
  # - Uses separate queries for different metrics
  # - Limits recent data to 10 items for page performance
  def index
    @total_users = User.where.not(system_role: "super_admin").count
    @active_users = User.active.where.not(system_role: "super_admin").count
    @inactive_users = User.inactive.count
    @locked_users = User.locked.count
    @recent_users = User.where.not(system_role: "super_admin").order(created_at: :desc).limit(10)
    @recent_activities = User.where.not(system_role: "super_admin").order(last_activity_at: :desc).limit(10)
  end
end
