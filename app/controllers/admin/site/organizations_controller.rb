class Admin::Site::OrganizationsController < Admin::Site::BaseController
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
