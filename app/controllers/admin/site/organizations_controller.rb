# Site Admin Organizations Controller
#
# PURPOSE:
# Provides site admin interface for viewing all organizations (teams + enterprise groups) 
# in a unified view for customer support purposes.
#
# ACCESS RESTRICTIONS:
# - Site admins have READ-ONLY access to organization data
# - Cannot create, edit, or delete teams or enterprise groups
# - Cannot access billing information
# - Inherits from Admin::Site::BaseController which enforces site_admin role
#
# BUSINESS RULES:
# - Combines teams and enterprise groups into unified "organizations" view
# - Site admins provide support but cannot create organizations (only super admins can)
# - Teams and enterprise groups are separate ecosystems but grouped for support
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Shows both team-based and enterprise user ecosystems
# - Helps site admins understand customer organizational structure
# - No crossover capabilities between organization types
class Admin::Site::OrganizationsController < Admin::Site::BaseController
  # Unified organizations dashboard showing teams and enterprise groups with tabbed interface
  #
  # TABBED INTERFACE:
  # - "teams" tab: Shows all team-based organizations
  # - "enterprise" tab: Shows all enterprise group organizations
  # - Default to teams tab for most common support cases
  #
  # STATISTICS CALCULATED:
  # - Total organizations across both types
  # - Active counts for operational insights
  # - Total members across all organizations
  # - Paid teams count (excluding free starter plans)
  #
  # SECURITY:
  # - Uses Pundit policy_scope for both Teams and EnterpriseGroup models
  # - Site admins see all organizations for support purposes
  #
  # PERFORMANCE OPTIMIZATIONS:
  # - Includes admin and users associations to prevent N+1 queries
  # - Separate pagination for each tab to maintain state
  # - Statistics calculated before pagination for accuracy
  #
  # SUPPORT USE CASES:
  # - View all customer organizations in one place
  # - Understand organization structure for support tickets
  # - Monitor organizational growth and activity
  def index
    @tab = params[:tab] || "teams"  # Default to teams tab

    # Base queries for stats
    teams_base = policy_scope(Team)
    enterprise_groups_base = policy_scope(EnterpriseGroup)

    # Combined stats (calculated before pagination)
    @total_organizations = teams_base.count + enterprise_groups_base.count
    @active_teams = teams_base.active.count
    @active_enterprise_groups = enterprise_groups_base.active.count
    @total_members = teams_base.joins(:users).count + enterprise_groups_base.joins(:users).count
    @paid_teams = teams_base.where.not(plan: "starter").count

    # Apply pagination based on tab
    case @tab
    when "enterprise"
      @show_teams = false
      @show_enterprise_groups = true
      @enterprise_groups = enterprise_groups_base.includes(:admin, :users).order(created_at: :desc)
      @pagy_enterprise, @enterprise_groups = pagy(@enterprise_groups, page_param: :enterprise_page)
    else # "teams" (default)
      @show_teams = true
      @show_enterprise_groups = false
      @teams = teams_base.includes(:admin, :users).order(created_at: :desc)
      @pagy_teams, @teams = pagy(@teams, page_param: :teams_page)
    end
  end
end
