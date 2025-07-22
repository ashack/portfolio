# Super Admin Analytics Controller
#
# PURPOSE:
# Provides comprehensive system analytics and business intelligence for super administrators.
# Super admins have full access to platform-wide statistics, user analytics, and growth metrics.
#
# ACCESS RESTRICTIONS:
# - Only super admins can access this controller
# - Full access to all user, team, and enterprise analytics
# - Can see sensitive business metrics and growth data
# - Inherits from Admin::Super::BaseController which enforces super_admin role
#
# BUSINESS INTELLIGENCE:
# - Platform-wide user statistics across all user types
# - Team and enterprise group growth analytics
# - Activity and engagement metrics
# - Monthly trend analysis for business planning
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Aggregates data across direct, team, and enterprise user ecosystems
# - Provides insights into each user type's performance
# - Supports strategic decision-making for platform growth
class Admin::Super::AnalyticsController < Admin::Super::BaseController
  # Analytics shows statistics, not scoped resources
  skip_after_action :verify_policy_scoped, only: :index
  skip_after_action :verify_authorized, only: :index

  # Comprehensive analytics dashboard for super admin strategic insights
  #
  # USER ANALYTICS:
  # - Total users across all types (including super admins)
  # - User distribution by status (active/inactive/locked)
  # - User distribution by type (direct/invited/enterprise)
  #
  # ORGANIZATIONAL ANALYTICS:
  # - Total teams and status distribution
  # - Team growth patterns and trends
  #
  # ENGAGEMENT ANALYTICS:
  # - Active users in last 30 days (platform health)
  # - New user acquisition in last 30 days
  # - New team creation in last 30 days
  # - Sign-in frequency and engagement patterns
  #
  # GROWTH ANALYTICS:
  # - Monthly user registration trends (12 months)
  # - Monthly team creation trends (12 months)
  # - Historical growth patterns for business planning
  #
  # PERFORMANCE CONSIDERATIONS:
  # - Manual grouping for monthly data (database-agnostic)
  # - Multiple separate queries for different metrics
  # - Could be optimized with background job for large datasets
  def index
    # User analytics
    @total_users = User.count
    @users_by_status = User.group(:status).count
    @users_by_type = User.group(:user_type).count

    # Team analytics
    @total_teams = Team.count
    @teams_by_status = Team.group(:status).count

    # Activity analytics
    @active_users_last_30_days = User.where("last_activity_at > ?", 30.days.ago).count
    @new_users_last_30_days = User.where("created_at > ?", 30.days.ago).count
    @new_teams_last_30_days = Team.where("created_at > ?", 30.days.ago).count

    # Sign in analytics
    @sign_ins_last_30_days = User.where("last_sign_in_at > ?", 30.days.ago).count
    @average_sign_in_count = User.average(:sign_in_count).to_f.round(1)

    # Monthly data (last 12 months) - manual grouping
    @users_by_month = {}
    @teams_by_month = {}
    12.times do |i|
      month = i.months.ago.beginning_of_month
      month_end = month.end_of_month
      @users_by_month[month] = User.where(created_at: month..month_end).count
      @teams_by_month[month] = Team.where(created_at: month..month_end).count
    end
  end
end
